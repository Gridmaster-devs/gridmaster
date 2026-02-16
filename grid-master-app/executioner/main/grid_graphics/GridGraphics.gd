class_name GridGraphics
extends Control
## Class / Node that is responsible for drawing the grid graphics of the game

var tile_size = 64
@onready var ui_map_grid = $"SubViewportContainer/Grid Graphics Viewport/TileGrid"
@onready var background_grid = $"SubViewportContainer/Grid Graphics Viewport/BackgroundGrid"
@onready var grid_graphics_viewport = $"SubViewportContainer/Grid Graphics Viewport"
@onready var tile_grid = $"SubViewportContainer/Grid Graphics Viewport/TileGrid"
var game_master : GameMaster

## array of the currently drawn units, should only be used for drawing purposes 
## maybe later just have it take the texture from the unit? 
var active_units: Array[UnitContainer]


## Gives this object a reference to the game master, and connects
## its signals to functions in this object
func linkGameMaster(game_master_p : GameMaster):
	game_master = game_master_p
	game_master.units_changed.connect(unitsChanged)


## Called by the game master at the start
func initFromGameGrid(game_grid : GameGrid):
	grid_graphics_viewport.resize(self.size)
	initTileGrid(game_grid)
	initBackgroundGrid(game_grid)
	getUnits()


## initializes tile sources for the tileMapLayer from the loaded GameGrid
## should only be called from initTileGrid
func initTileSources(game_grid: GameGrid) -> void: 
	for tile_type in game_grid.strategic_tile_types.values():
		var source = TileSetAtlasSource.new()
		source.texture = tile_type.texture
		source.texture_region_size = Vector2i(64, 64)
		source.create_tile(Vector2i(0,0))
		ui_map_grid.tile_set.add_source(source, tile_type.type_id)


## initializes the map element of the game from data loaded into the game_state
func initTileGrid(game_grid : GameGrid) -> void: 
	initTileSources(game_grid)
	for y in range(game_grid.tiles.height):
		for x in range(game_grid.tiles.width):
			var id = game_grid.getTileType(x, y).type_id
			ui_map_grid.set_cell(Vector2i(x, y), id , Vector2i(0,0), 0) 


## Converts game grid coordinates to screen coordinates
func gridToScreen(grid_pos: Vector2i) -> Vector2i: 
	return Vector2i(grid_pos.x * tile_size + tile_size / 2, grid_pos.y * tile_size + tile_size / 2)


## Initializes the background grid
func initBackgroundGrid(game_grid): 
	background_grid.resize(game_grid.getWidth(), game_grid.getHeight())


## Removes all active units
func clearUnits():
	for i in active_units.size():
		var unit = active_units.front()
		active_units.remove_at(0)
		unit.queue_free()


## Gets the units from the game master and puts them in the active units array
func getUnits():
	if (game_master != null):
		var units = game_master.getUnits()
		if (units != null):
			clearUnits()
			for unit : Unit in units:
				var unit_container = UnitContainer.new(unit, gridToScreen(unit.getPosition()))
				addNewUnitContainer(unit_container)


## Adds a new unit container to the active units array
func addNewUnitContainer(unit_cont: UnitContainer): 
	active_units.append(unit_cont)
	grid_graphics_viewport.add_child(unit_cont)


## Called when the Game Master emits the units_changed signal
func unitsChanged() -> void:
	clearUnits()
	getUnits()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
