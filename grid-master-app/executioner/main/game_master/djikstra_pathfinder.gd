class_name DjikstraPathfinder
extends RefCounted

# NOTE: If this is too slow it can be rewritten in a high-performance language 

var _djikstra_grid : Array2D
var _game_grid : GameGrid
var _grid_width : int
var _grid_height : int
var _possible : Array[Vector2i] = [] # Possible to reach tiles


## Initializes the Djikstra Pathfinder's grid from a game_grid.
## Only needs to be called once when a game is started.
func add_game_grid(game_grid : GameGrid) -> void:
	assert(game_grid != null, "Tried giving null game grid to Djikstra Pathfinder!")
	_game_grid = game_grid
	_grid_width = _game_grid.getWidth()
	_grid_height = _game_grid.getHeight()
	_djikstra_grid = Array2D.new(_grid_width, _grid_height)
	
	var fill_func = func(x, y):
		return DjikstraNode.new(Vector2i(x, y))
	
	_djikstra_grid.fill(fill_func)
	update_grid()
	

## Updates the values of the tiles on the grid.
## Call if grid tile movement values change.
func update_grid() -> void:
	for y in range(0, _grid_height):
		for x in range(0, _grid_width):
			var tile_type : TileType = _game_grid.getTileType(x, y)
			var node : DjikstraNode = _djikstra_grid.getItem(x, y)
			node.movement = tile_type.get_attribute(TileType.TILE_ATTRIBUTE_TYPE.MOVEMENT)


func get_neighbors(position : Vector2i):
	pass


## Returns an array of all tiles that are possible to reach from
## the starting position with a set amount of movement
func tiles_from_position(start_position : Vector2i, movement : int) -> Array[Vector2i]:
	var unvisited := PriorityQueue.new(DjikstraNode.priority_func)
	
	var start_node : DjikstraNode = _djikstra_grid.get_item_vec(start_position)
	start_node.movement_required = 0
	_possible.append(start_position)
	unvisited.add_item(start_position)
	


## Class that represents a node in the pathfinder
class DjikstraNode extends RefCounted:
	# Largest number an int can store, acting as infinity here
	static var MAX_INT : int = 9223372036854775807
	
	var position : Vector2i
	var movement : int = 1
	
	var visited : bool = false
	var previous : Vector2i = Vector2i(-1, -1)
	var movement_required : int = MAX_INT


	## Returns the movement required value for the djikstra algorithm
	static func priority_func(node : DjikstraNode):
		return node.movement_required
		

	func _init(position_p : Vector2i):
		position = position_p
