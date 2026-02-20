class_name GridGraphics
extends Control
## Class / Node that is responsible for drawing the grid graphics of the game

## Size for the tiles of the grid.
## This is the internal size of the grid for the godot engine,
## not the resolution. 
const TILE_SIZE = 64

const GROUP_NAME : StringName = "GridGraphics"
const EVENT_INPUT_FUNC_NAME : StringName = "handle_input"

## What state the grid graphics object is in
# DEFAULT: Only the selected tile hover graphic is drawn
# UNIT_MOVE: Selected tile and the path from the last waypoint to the cursor is drawn
enum GraphicsState {DEFAULT, UNIT_MOVE}

@onready var ui_map_grid = $"SubViewportContainer/Grid Graphics Viewport/TileGrid"
@onready var background_grid = $"SubViewportContainer/Grid Graphics Viewport/BackgroundGrid"
@onready var grid_graphics_viewport = $"SubViewportContainer/Grid Graphics Viewport"
@onready var tile_grid : TileMapLayer = $"SubViewportContainer/Grid Graphics Viewport/TileGrid"
@onready var custom_graphics : CustomGraphics = $"SubViewportContainer/Grid Graphics Viewport/CustomGraphics"


var graphics_state : GraphicsState = GraphicsState.DEFAULT

# Variables for UNIT_MOVE
var possible_movement_tiles : Array[Vector2i]
var moved_unit_pos : Vector2i


var game_master : GameMaster # NOTE: Might be unnecessary when using groups
var _grid_width : int
var _grid_height : int


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
	
	_grid_width = game_grid.getWidth()
	_grid_height = game_grid.getHeight()
	
	for y in range(game_grid.tiles.height):
		for x in range(game_grid.tiles.width):
			var id = game_grid.getTileType(x, y).type_id
			ui_map_grid.set_cell(Vector2i(x, y), id , Vector2i(0,0), 0) 


## Converts game grid coordinates to screen coordinates
func gridToScreen(grid_pos: Vector2i) -> Vector2: 
	return Vector2(grid_pos.x * TILE_SIZE + TILE_SIZE / 2.0, grid_pos.y * TILE_SIZE + TILE_SIZE / 2.0)


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


## Returns the coordinates of the tile that 
## the user currently has their mouse over.
## Returns (-1, -1) if the player is not hovering over any tile.
func get_current_hovered_tile_coords() -> Vector2i:
	# Mouse position local to the Tile Map Grid
	var mouse_pos_local : Vector2 = tile_grid.get_local_mouse_position()
	var x_pos : int = floor(mouse_pos_local.x / TILE_SIZE)
	var y_pos : int = floor(mouse_pos_local.y / TILE_SIZE)
	
	# Checking if coords are out of bounds
	if (x_pos < 0 or x_pos >= _grid_width or y_pos < 0 or y_pos >= _grid_height):
		return Vector2i(-1, -1)
	else:
		return Vector2i(x_pos, y_pos)


func get_custom_graphics() -> CustomGraphics:
	return custom_graphics


func _ready() -> void:
	pass
