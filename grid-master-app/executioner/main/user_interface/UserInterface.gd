class_name UserInterface
extends Control

@onready var ftm : FileTransferManager = $Dialogs/FileTransferManager
@onready var grid_graphics : GridGraphics = $"Grid Graphics"
@onready var game_name_box : Label = $"Game Name"
var game_master : GameMaster


## Opens the load game dialog
func openLoadGameDialog() -> void:
	ftm.upload_data("*.tres", true)


## Initializes the user interface object from a game state at the start of the game
func initFromGameState(game_state : GameState) -> void:
	# Initialize grid graphics child
	grid_graphics.initFromGameGrid(game_state.getGameGrid())
	
	# Initialize the game name object
	game_name_box.text = game_state.getGameName()

## Called by the load game dialog
func loadGameDefinition(game_definition : Resource):
	assert(game_definition != null, "Invalid game definition in file!")
	game_master.playerSelectedGameDefinition(game_definition)


## Gives this object a reference to the game master
##
## Called by the game master when a game is started to give a reference to itself
## Also initializes user interface's children
func linkGameMaster(game_master_p : GameMaster) -> void:
	game_master = game_master_p
	grid_graphics.linkGameMaster(game_master)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ftm.resource_uploaded.connect(loadGameDefinition)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
