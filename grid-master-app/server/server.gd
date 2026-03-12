## This is the entrypoint for the game server
## Handles incoming WebSocket multiplayer connections and maintains the list of connected players.

extends Node

# TODO: GameAction subclasses are something around which we want to build the gamestate updating logic
#		(UnitAction, PlayerAction etc.)

# TODO: GameState object should be an synchronized (use MultiplayerSynchronizer) object that's
#		shared between server and the clients. The client should.

## Configurable server variables
const PORT = 55555

## The core game server instance
var server = WebSocketMultiplayerPeer.new()

## Dictionary that maps network peer IDs (int) to Player representations (Player.gd)
var players : Dictionary = {}

## Create and initialize the server object
func start_server():
	print("Starting server..")
	multiplayer.multiplayer_peer = null
	var err = server.create_server(PORT)
	if err != OK:
		printerr("Failed to create the server instance. Error code: %d" % err)
	multiplayer.multiplayer_peer = server

func _ready():
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	start_server()

## Fired when a peer connects to the server
func _peer_connected(id):
	print("Connected %d" % id)
	var PlayerClass = load("res://executioner/main/game_master/Player.gd")

	# Instantiate a new Player
	var new_player = PlayerClass.new()
	new_player.player_id = id
	# Assign teams based on connection order
	new_player.team_id = players.size()
	new_player.computer = false
	new_player.player_name = "Player %d" % id

	players[id] = new_player

	# TODO: The server needs to add the player to the world, assign the correct team to itself
	#		and set the appropriate values for it.

## Fired when a peer disconnects from the server
func _peer_disconnected(id):
	if players.has(id):
		players.erase(id)
	print("Disconnected %d" % id)

