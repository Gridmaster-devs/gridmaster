#!/usr/bin/env bash
# Run the multiplayer game server and clients locally from source, with no
# exports or Docker needed. See docs/integration-testing.md.
#
#   ./local-multiplayer.sh                  server + 2 game client windows
#   ./local-multiplayer.sh --clients 3      server + 3 client windows
#   ./local-multiplayer.sh --server-only    just the server (in the foreground)
#   ./local-multiplayer.sh --smoke [game]   headless check: upload a game, join
#                                           2 players, play one turn; exits 0/1
#
# Environment: GODOT (Godot 4.5.1 binary, default "godot"), GRIDMASTER_PORT
# (default 8082; the client's server browser lists ws://127.0.0.1:8082),
# GRIDMASTER_BIND (default 127.0.0.1; the server accepts uploads without
# authentication, so only set 0.0.0.0 on a network you trust).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$REPO_DIR/grid-master-app"
GODOT="${GODOT:-godot}"
PORT="${GRIDMASTER_PORT:-8082}"
BIND="${GRIDMASTER_BIND:-127.0.0.1}"
DEFAULT_SMOKE_GAME="$APP_DIR/Production test.tres"
SMOKE_CLIENT="res://tools/multiplayer_smoke_client.gd"

mode="clients"
clients=2
smoke_game="$DEFAULT_SMOKE_GAME"

while [[ $# -gt 0 ]]; do
	case "$1" in
		--clients) clients="$2"; shift 2 ;;
		--server-only) mode="server"; shift ;;
		--smoke)
			mode="smoke"; shift
			if [[ $# -gt 0 && "$1" != --* ]]; then smoke_game="$(realpath "$1")"; shift; fi
			;;
		-h|--help) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
		*) echo "Unknown option: $1 (see --help)" >&2; exit 2 ;;
	esac
done

if ! command -v "$GODOT" >/dev/null 2>&1; then
	echo "Godot not found. Install Godot 4.5.1 or set GODOT=/path/to/godot." >&2
	exit 1
fi

# A fresh checkout has no .godot/ folder (it's gitignored), and without the
# script class cache it builds, class_name types don't resolve when the
# project is run directly. The editor or an import creates it.
if [[ ! -f "$APP_DIR/.godot/global_script_class_cache.cfg" ]]; then
	echo "Importing the Godot project (first run only)..."
	"$GODOT" --headless --path "$APP_DIR" --import >/dev/null 2>&1 || {
		echo "Godot project import failed. Open grid-master-app/ in the Godot editor once, then retry." >&2
		exit 1
	}
fi

LOG_DIR="$(mktemp -d "${TMPDIR:-/tmp}/gridmaster-mp.XXXXXX")"
pids=()
cleanup() {
	for pid in "${pids[@]}"; do kill "$pid" 2>/dev/null || true; done
	wait 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 130' INT TERM

start_server() {
	"$GODOT" --headless --path "$APP_DIR" res://server/Server.tscn -- "--port=$PORT" "--bind=$BIND" >"$LOG_DIR/server.log" 2>&1 &
	pids+=("$!")
	local server_pid=$!
	for _ in $(seq 1 50); do
		if grep -q "Server listening on port" "$LOG_DIR/server.log" 2>/dev/null; then
			echo "Server listening on ws://$BIND:$PORT (log: $LOG_DIR/server.log)"
			return 0
		fi
		if ! kill -0 "$server_pid" 2>/dev/null; then
			echo "Server failed to start:" >&2
			cat "$LOG_DIR/server.log" >&2
			return 1
		fi
		sleep 0.2
	done
	echo "Server didn't report listening within 10 s. Log: $LOG_DIR/server.log" >&2
	return 1
}

# Starts a headless smoke client in the background and sets $last_pid to the
# Godot process itself, so cleanup can kill it and `wait` stays interruptible.
start_smoke_client() { # <log name> <args...>
	local name="$1"; shift
	"$GODOT" --headless --path "$APP_DIR" -s "$SMOKE_CLIENT" -- "--url=ws://127.0.0.1:$PORT" "$@" >"$LOG_DIR/$name.log" 2>&1 &
	last_pid=$!
	pids+=("$last_pid")
}

# Prints "start end" from a player's "[smoke] turns: start=N end=M" line.
smoke_turns() {
	sed -n 's/^\[smoke\] turns: start=\(-\{0,1\}[0-9]*\) end=\(-\{0,1\}[0-9]*\)$/\1 \2/p' "$LOG_DIR/$1.log"
}

case "$mode" in
	server)
		echo "Starting server on port $PORT (Ctrl-C to stop)"
		exec "$GODOT" --headless --path "$APP_DIR" res://server/Server.tscn -- "--port=$PORT" "--bind=$BIND"
		;;

	clients)
		if [[ "$PORT" != 8082 ]]; then
			# The client's server browser has a fixed list (ServerBrowserGUI.SERVERS).
			echo "Game clients can only reach port 8082. Use --server-only or --smoke for other ports." >&2
			exit 2
		fi
		start_server
		for i in $(seq 1 "$clients"); do
			"$GODOT" --path "$APP_DIR" res://executioner/main/game_master/GameMaster.tscn >"$LOG_DIR/client$i.log" 2>&1 &
			pids+=("$!")
		done
		cat <<-EOF
		Started $clients client window(s). Logs: $LOG_DIR
		In ONE client: Multiplayer -> the "ws://127.0.0.1:$PORT" server -> Upload New Game.
		Then in every client: Multiplayer -> same server -> Play -> pick a different team.
		The turn advances once every connected player has ended their turn.
		Ctrl-C here stops the server and all clients.
		EOF
		wait
		;;

	smoke)
		[[ -f "$smoke_game" ]] || { echo "Game file not found: $smoke_game" >&2; exit 1; }
		start_server
		status=0
		start_smoke_client upload "--upload=$smoke_game"
		if wait "$last_pid"; then
			start_smoke_client player0 --player=0
			p0=$last_pid
			start_smoke_client player1 --player=1
			p1=$last_pid
			wait "$p0" || status=1
			wait "$p1" || status=1
			# Both players must have played the same turn together. If one finished
			# a turn alone before the other joined, their turn numbers differ.
			t0="$(smoke_turns player0)"; t1="$(smoke_turns player1)"
			read -r s0 e0 <<<"${t0:-x x}"
			if [[ $status -eq 0 && ( -z "$t0" || "$t0" != "$t1" || "$e0" != "$((s0 + 1))" ) ]]; then
				echo "Players didn't share one turn (player0: ${t0:-none}, player1: ${t1:-none})." >&2
				status=1
			fi
		else
			status=1
		fi
		for name in upload player0 player1; do
			[[ -f "$LOG_DIR/$name.log" ]] && grep -h '^\[smoke\]' "$LOG_DIR/$name.log" | sed "s/^/$name: /"
		done
		if [[ $status -eq 0 ]]; then
			echo "SMOKE TEST PASSED"
		else
			echo "SMOKE TEST FAILED. Logs: $LOG_DIR" >&2
			grep -E 'ERROR|FATAL' -A3 "$LOG_DIR/server.log" >&2 || true
		fi
		exit "$status"
		;;
esac
