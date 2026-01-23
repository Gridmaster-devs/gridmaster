# Integration testing

The usage of the local integration testing environment is documented here. The local integration testing environment is a docker compose -managed orchestration of containers which encapsulate the different components of the gridmaster application. 

## Prerequisites

- Docker desktop accessible from your terminal of choice

## Usage

Before running docker compose, you must build the godot project using the Godot editor into the following directory `/grid-master-app/build/`. Use the web export preset. (Better automation WIP)

Then simply run

> docker compose up

Which will run the default compose file `compose.yaml`.

Now when you pop `localhost:8080` in your browser, you'll be able to access the nginx web server that serves the game editor (the only real component of the app for now).

## TODO

The integration testing environment isn't terribly useful right now since there's no implementation of any components beside the editors.

## Troubleshooting

### The containers don't appear to reflect my most recent changes

Try running 

> docker compose up --build --force-recreate

instead. This forces docker to rebuild the containers from scratch so your most recent changes are copied into the containers.

However, sometimes your browser may be the issue, caching an old version of the web app and not detecting changes. Force the browser to load all files from the server by deleting all data for the specific site. 