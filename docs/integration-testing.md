# Integration testing

There are two ways to run the whole application locally:

- **From source** (`local-multiplayer.sh`): the fastest way to test multiplayer. It runs the game server and game clients straight from the Godot project, so there's no export or Docker step.
- **Docker compose**: runs the exported web builds behind nginx, the same way they run in production.

## Local multiplayer from source

### Prerequisites

- Godot 4.5.1 on your `PATH` as `godot`, or set `GODOT=/path/to/godot`
- A bash shell (Linux, macOS, WSL or Git Bash)

### Play it yourself

> ./local-multiplayer.sh

This starts the server on `ws://127.0.0.1:8082` and opens two game client windows. Then:

1. In one client, click **Multiplayer**, select the `ws://127.0.0.1:8082` server, click **Upload New Game** and pick a game file.
2. In each client, click **Multiplayer**, select the same server, click **Play** and pick a different team.
3. End the turn in every client. The server advances the turn once every connected player has ended theirs.

Ctrl-C stops the server and all clients. Use `--clients N` for a different number of windows, or `--server-only` to run just the server, for example when you start the clients from the Godot editor. The client's server list is fixed, so the client windows only work with the default port 8082.

### Automated smoke test

> ./local-multiplayer.sh --smoke [path/to/game.tres]

This runs headless: it uploads a game (default `grid-master-app/Production test.tres`), joins two players to different teams, plays one turn, and exits 0 on success. With the default loopback binding, it also checks that both clients observe the same spawn before the turn advances and report the same server turn duration.

### Developer console

The console is available in debug builds after you load a single-player game or connect to a debug server at `127.0.0.1` and join a match. In Godot, run `executioner/main/game_master/GameMaster.tscn` directly. For multiplayer, run `server/Server.tscn` from a second Godot instance or use this command from the repository root.

```sh
godot --headless --path grid-master-app res://server/Server.tscn
```

The source server starts at `ws://127.0.0.1:8082`. Follow the upload and team selection steps above. Use matching debug builds of the server and clients to open the console.

Press **F2** to open the console, **Enter** to run the command and **Esc** to close it. Try `types` to find an exact unit type name, then `spawn "Heavy Infantry" 3 5` if that type is registered and the tile is empty. Coordinates are zero-based. In multiplayer, the new unit belongs to the player mapped to the requesting peer and appears on the clients' boards subject to the normal fog of war. Use `units` to inspect the full board state.

Within double quotes, type `\"` for a quote and `\\` for a backslash in a unit name.

For an overlay check, open the console over a loaded game, verify the input has focus, and try clicking the board and **End Turn** while it is open. Close it with **Esc** and check that gameplay input works again. **F2** should leave the overlay closed in release builds and on servers without console support.

#### Headless GDScript API

In a GUT test, instantiate the Executioner scene, add it to the tree, and load a game. The same runner used by the overlay is available without opening it.

```gdscript
var console: DeveloperConsole = game_master.get_node("DeveloperConsole")
var result: Dictionary = await console.DEBUG_execute("state")
assert_true(result["ok"])
assert_eq(result["data"]["turn_number"], 0)
```

Each result has `ok` (boolean), `code` (string), `message` (display text), and `data` (dictionary of plain values). A successful result uses code `ok`. Errors have an empty `data` dictionary.

| Command | Success data |
| --- | --- |
| `help` | `commands`, a dictionary from command names to syntax |
| `spawn "Unit Type" X Y` | `unit_id` |
| `state` | `game_name`, `mode` (`singleplayer` or `multiplayer`), `turn_number` (completed turns), `width`, `height`, `active_player_id` (this client's player), `unit_count`, `game_over` |
| `units` | `units`, an array of entries with `id`, `type`, `player_id`, `x`, `y`, and `hp` |
| `types` | `types`, an array of exact registered names |
| `perf` | `fps` and `turn_processing_ms`. Headless FPS and the turn sample before the first completed turn are `null`, displayed as `N/A`. |

Stable error codes are `unavailable`, `empty_command`, `unknown_command`, `invalid_syntax`, `invalid_arguments`, `invalid_coordinates`, `unknown_unit_type`, `out_of_bounds`, `occupied`, `game_over`, `not_joined`, `spawn_pending`, `request_failed`, `disconnected`, `session_changed`, and `timeout`. Multiplayer permits one pending spawn per client. After a five-second timeout, an authoritative update can still reach the board. Inspect `units` before retrying.

### Notes

- Source runs use port 8082. Server exports use port 443 for Docker and Azure. Override the port with `-- --port=N` after the scene path or set `GRIDMASTER_PORT`.
- Source runs bind to `127.0.0.1`. The server accepts game uploads from anyone without authentication, and a game file can contain code, so don't expose it on a network you don't trust. To test from another device, set `GRIDMASTER_BIND=0.0.0.0` or pass `-- --bind=0.0.0.0` when running the server by hand.
- **Old game files:** `game.tres`, `orcs_humans_elves.tres` and `game_cats_dogs*.tres` were saved before units had IDs, and the server rejects them. Re-saving them in the editor doesn't add the IDs, so use `Production test.tres` or a game made in the current editor.
- **File size:** uploads and game file downloads are limited to 10 MB, the WebSocket buffer size. `game editor test.tres` is 25 MB and doesn't fit.

## Docker compose

The docker compose setup runs the exported builds in containers: the editors, the web client and the game server.

### Prerequisites

- Docker desktop accessible from your terminal of choice

### Usage

Before running docker compose, export the Godot project from the Godot editor with all three export presets: `editor-web`, `client-web` and `server`. They write to `grid-master-app/build/editor-web/`, `build/client-web/` and `build/server/`. (Better automation WIP)

Then simply run

> docker compose up

Which will run the default compose file `compose.yaml`.

Now when you pop `localhost:8080` in your browser, you'll be able to access the nginx web server that serves the game editor, and you'll find the game executioner at `localhost:8081`. The game server is at `ws://127.0.0.1:8082`, the second entry in the client's server browser.

### Troubleshooting

#### The containers don't appear to reflect my most recent changes

Try running 

> docker compose up --build --force-recreate

instead. This forces docker to rebuild the containers from scratch so your most recent changes are copied into the containers.

However, sometimes your browser may be the issue, caching an old version of the web app and not detecting changes. Force the browser to load all files from the server by deleting all data for the specific site.
