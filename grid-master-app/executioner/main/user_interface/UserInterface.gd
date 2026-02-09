class_name UserInterface
extends Control

@onready var ftm : FileTransferManager = $Dialogs/FileTransferManager
var game_master : GameMaster


## Opens the load game dialog
func openLoadGameDialog() -> void:
	ftm.upload_data("*.tres", true)


## Called by the load game dialog
func loadGameDefinition(game_definition : Resource):
	assert(game_definition != null, "Invalid game definition in file!")
	game_master.playerSelectedGameDefinition(game_definition)


## Called by the game master to give a reference to itself
func linkGameMaster(game_master_p : GameMaster) -> void:
	game_master = game_master_p


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ftm.resource_uploaded.connect(loadGameDefinition)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
