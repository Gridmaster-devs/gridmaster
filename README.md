# Gridmaster

## About
Gridmaster is a 2D strategy game engine

## For Developers

### Prerequisites:

- Godot editor (project version currently pinned to v4.5.1)
- Docker for easy testing of a browser deployment

The easiest way to develop Godot projects is using the Godot editor. This is also our recommended approach.

### Project structure

The root of the Godot portion of this project is at `/grid-master-app/` and is the folder you should open in the Godot editor.

There are two sub-projects (but treated as a single Godot project for ease of use) in the `grid-master-app/` folder: 
- the `editor/` folder includes the code for the GridMaster editors which can be used to produce map, unit and game definitions that can be loaded into the game engine
- the `executioner/`folder includes the code for the game client that lets you play games based on a provided game definition

### Getting started

1. Download the Godot editor v4.5.1
2. Clone this repository onto your local machine
2. Open the Godot editor and import the project by navigating to the location you cloned the repository to and opening `/grid-master-app/` (the editor will recognize the folder as a Godot project)
4. For more information on running tests or using the Docker-enabled integration testing environment to easily test your changes in the browser as intended, see the `/docs/` folder for the respective instructions.

### Additional Info

The original development team codified a set of quality standards and guidelines to maintain consistency. The same document also outlines key implementation and architecture details. Recommended reading for all contributors:

[Guidelines and Documentation](https://docs.google.com/document/d/1XhUxc3291oeITSUw76szaOw3W2Dfyhj9IsBo4iZ9_4E/edit?tab=t.0#heading=h.urgqepjjn5gw)



