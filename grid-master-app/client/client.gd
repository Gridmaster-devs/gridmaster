extends Node

var client = WebSocketMultiplayerPeer.new()

const PORT = 55555

func start_connect():
	print("Starting connect")
	multiplayer.multiplayer_peer = null
	var err = client.create_client("ws://" + "localhost"  + ":" + str(PORT))
	if !err:
		printerr("Failed to create client. Error code: %d" %err)
	multiplayer.multiplayer_peer = client

func _ready():
	multiplayer.connection_failed.connect(_close_network)
	multiplayer.connected_to_server.connect(_connected)
	multiplayer.server_disconnected.connect(_disconnected)
	start_connect()

func _close_network():
	print("Connection failed")

func _connected():
	print("Connected to server")
	
func _disconnected():
	print("Disconnected from server")
