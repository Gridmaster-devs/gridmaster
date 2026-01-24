class_name GameMaster
extends Node
## Game master class which manages the game state and communicates
## with other game elements

var game_state : GameState ## The state of the game
var tile_size = 64
@onready var user_interface : UserInterface = $"User Interface"
@onready var ui_map_grid = $"User Interface/SubViewportContainer/SubViewport/TileGrid"
@onready var game_name_ui = $"User Interface/GameName"
@onready var sub_viewport = $"User Interface/SubViewportContainer/SubViewport"
@onready var background_grid = $"User Interface/SubViewportContainer/SubViewport/BackgroundGrid"

## array of the currently drawn units, should only be used for drawing purposes 
## maybe later just have it take the texture from the unit? 
var active_units: Array[UnitContainer]


# This is ONLY for drawing the map and the units!!
# Only the game master should EVER modify the game state
## Returns the game grid if the game state is initialized
func getGameGrid() -> Variant:
	if game_state == null:
		return null
	else:
		return game_state.getGameGrid()


# This is ONLY for drawing the map and the units!!
# Only the game master should EVER modify the game state
## Returns the units in the game if the game state is initialized
func getUnits() -> Variant:
	if game_state == null:
		return null
	else:
		return game_state.getUnits()


# DEBUG ONLY!!
## Creates a debug unit for testing
func createDebugUnit(position : Vector2i) -> void:
	if game_state != null:
		var new_unit_cont = UnitContainer.new(game_state.createDebugUnit(position), gridToScreen(position))
		addNewUnitContainer(new_unit_cont)
		
		
## SOLELY FOR TESTING
## NEVER EVER USE IN ACTUAL PRODUCTION CODE
func createUnit(unit_type_id : int, position : Vector2i) -> void:
	var new_unit_cont = UnitContainer.new(game_state.addUnitByTypeId(unit_type_id, position, -1), gridToScreen(position)) 
	addNewUnitContainer(new_unit_cont)
	
	

func addNewUnitContainer(unit_cont: UnitContainer): 
	active_units.append(unit_cont)
	sub_viewport.add_child(unit_cont)


func getGameName() -> String:
	if game_state != null:
		return game_state.getGameName()
	else:
		return ""


## Initializes a game state from a game definition
func initGameStateFromGameDefinition(game_definition : GameDefinitionResource):
	game_state = GameState.initFromGameDefinition(game_definition)


## Called by the user interface when the player has selected a game definition file and hit the load button
func playerSelectedGameDefinition(game_definition : GameDefinitionResource):
	initGameStateFromGameDefinition(game_definition)
	game_name_ui.text = game_definition.game_name
	createUnit(0, Vector2i(0,0))
	initTileGrid()
	initBackgroundGrid()
	# DEBUG
	printTileTypes()
	printUnitTypes()
	printMap()


# DEBUG ONLY!!
## Creates a debug game for testing
func debugInitGame() -> void:
	game_state = GameState.debugInit(10, 10, "Test game")
	

## Prints the map into console
func printMap() -> void:
	if (game_state != null):
		game_state.printMap(true)
		

## Prints all the unit types into the console
func printUnitTypes() -> void:
	if (game_state != null):
		game_state.printUnitTypes(true)
		

## Prints all of the tile types into the console
func printTileTypes() -> void:
	if (game_state != null):
		game_state.printTileTypes(true)


## Creates a debug game, places some units, and prints the map
func debugTest():
	debugInitGame()
	game_state.createDebugUnit(Vector2i(0,0))
	game_state.createDebugUnit(Vector2i(5,5))
	printMap()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	user_interface.linkGameMaster(self)
	user_interface.openLoadGameDialog()
	
	
##initializes tile sources for the tileMapLayer from the loaded GameGrid
##should only be called from initTileGrid
func initTileSources(game_grid: GameGrid) -> void: 
	for tile_type in game_grid.strategic_tile_types.values():
		var source = TileSetAtlasSource.new()
		source.texture = tile_type.texture
		source.texture_region_size = Vector2i(64, 64)
		source.create_tile(Vector2i(0,0))
		ui_map_grid.tile_set.add_source(source, tile_type.type_id)

##initializes the map element of the game from data loaded into the game_state
func initTileGrid() -> void: 
	if(game_state != null):
		var game_grid = game_state.getGameGrid()
		initTileSources(game_grid)
		for y in range(game_grid.tiles.height):
			for x in range(game_grid.tiles.width):
				var id = game_grid.getTile(x, y).getTileType().type_id
				ui_map_grid.set_cell(Vector2i(x, y), id , Vector2i(0,0), 0) 

##converts game grid coordinates to screen coordinates
func gridToScreen(grid_pos: Vector2i) -> Vector2i: 
	return Vector2i(grid_pos.x * tile_size + tile_size / 2, grid_pos.y * tile_size + tile_size /2)
	
	
func initBackgroundGrid(): 
	if(game_state != null): 
		background_grid.resize(game_state.getGridWidth(), game_state.getGridHeight())
	
