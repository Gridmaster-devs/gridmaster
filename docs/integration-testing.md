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

This runs headless: it uploads a game (default `grid-master-app/Production test.tres`), joins two players to different teams, plays one turn, and exits 0 on success. Run it after changing networking or server code.

### Notes

- **Port:** the server listens on port 443 by default, which is what the Docker image and Azure expect. On Linux, including WSL, ports below 1024 need root, so the script uses port 8082. To run the server by hand, pass `-- --port=8082` after the scene path, or set `GRIDMASTER_PORT`.
- **Network access:** the script makes the server listen on `127.0.0.1` only. The server accepts game uploads from anyone without authentication, and a game file can contain code, so don't expose it on a network you don't trust. To test from another device, set `GRIDMASTER_BIND=0.0.0.0` (or pass `-- --bind=0.0.0.0` when running the server by hand).
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