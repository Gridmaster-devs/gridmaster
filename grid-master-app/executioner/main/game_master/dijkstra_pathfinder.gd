class_name DijkstraPathfinder
extends RefCounted

# NOTE: If this is too slow it can be rewritten in a high-performance language 

# Largest number an int can store, acting as infinity here
const MAX_INT : int = 9223372036854775807

var _djikstra_grid : Array2D
var _game_grid : GameGrid
var _grid_width : int
var _grid_height : int


## Initializes the Djikstra Pathfinder's grid from a game_grid.
## Only needs to be called once when a game is started.
func add_game_grid(game_grid : GameGrid) -> void:
	assert(game_grid != null, "Tried giving null game grid to Djikstra Pathfinder!")
	_game_grid = game_grid
	_grid_width = _game_grid.getWidth()
	_grid_height = _game_grid.getHeight()
	_djikstra_grid = Array2D.new(_grid_width, _grid_height)
	
	var fill_func = func(x, y):
		return DijkstraNode.new(Vector2i(x, y))
	
	_djikstra_grid.fill(fill_func)
	update_grid()
	

## Updates the values of the tiles on the grid.
## Call if grid tile movement values change.
func update_grid() -> void:
	for y in range(0, _grid_height):
		for x in range(0, _grid_width):
			var tile_type : TileType = _game_grid.getTileType(x, y)
			var node : DijkstraNode = _djikstra_grid.getItem(x, y)
			node.movement = tile_type.get_attribute(TileType.TILE_ATTRIBUTE_TYPE.MOVEMENT)


func get_neighbors(node : DijkstraNode) -> Array[DijkstraNode]:
	var neighbors : Array[DijkstraNode] = []
	var x = node.position.x
	var y = node.position.y
	
	if (x > 0):
		neighbors.append(_djikstra_grid.getItem(x-1,y))
	
	if (x < _grid_width - 1):
		neighbors.append(_djikstra_grid.getItem(x+1,y))
	
	if (y > 0):
		neighbors.append(_djikstra_grid.getItem(x,y-1))
	
	if (y < _grid_height - 1):
		neighbors.append(_djikstra_grid.getItem(x,y-1))
	
	return neighbors


func reset_nodes() -> void:
	var reset_func = func(node : DijkstraNode):
		node.movement_required = MAX_INT
		node.visited = false
		node.previous = null
	
	_djikstra_grid.foreach(reset_func, false)


## Returns an array of all tiles that are possible to reach from
## the starting position with a set amount of movement
func tiles_from_position(start_position : Vector2i, movement_available : int) -> Array[Vector2i]:
	var unvisited := PriorityQueue.new(DijkstraNode.priority_func)
	var possible : Array[Vector2i] = [] # Possible to reach tiles
	reset_nodes() # Reset the nodes from a previous calculation
	
	var start_node : DijkstraNode = _djikstra_grid.get_item_vec(start_position)
	start_node.movement_required = 0
	possible.append(start_position)
	unvisited.add_item(start_position)
	
	var current_node : DijkstraNode
	while(true):
		# Get the unvisited node with the lowest movement required
		current_node = unvisited.pop_first()
		
		# There are no nodes left, so we're done
		if current_node == null:
			break
		
		# There is a node to process
		else:
			current_node.visited = true
			
			# If our unit has enough movement to reach this tile
			if (current_node.movement_required <= movement_available):
				possible.append(current_node.position)
				
				var neighbors = get_neighbors(current_node)
				
				for node in neighbors:
					node.update_movement_req(current_node)
					if (node.visited == false):
						unvisited.add_item(node)
					
	return possible


## Returns a path from a previously calculated starting position
## (with tiles_from_position), if it exists
func get_path_to_pos(position : Vector2i) -> Array[Vector2i]:
	var path : Array[Vector2i] = []
	
	var current_node : DijkstraNode = _djikstra_grid.get_item_vec(position)
	while(true):
		path.append(current_node)
		current_node = current_node.previous
		if current_node == null: break
	
	# If path would only have the beginning position we return an empty array instead
	if (path.size() <= 1):
		return []
	else:
		return path



## Class that represents a node in the pathfinder.
class DijkstraNode extends RefCounted:
	
	var position : Vector2i
	var movement : int = 1
	
	var visited : bool = false
	var previous : DijkstraNode = null
	var movement_required : int = MAX_INT
	
	
	## Updates the movement_required and previous variables of the node if
	## the new movement required is less than previously.
	func update_movement_req(node : DijkstraNode) -> void:
		var prev_movement = node.movement_required
		if (prev_movement + movement) < movement_required:
			movement_required = prev_movement + movement
			previous = node


	## Returns the movement required value for the djikstra algorithm.
	static func priority_func(node : DijkstraNode):
		return node.movement_required
		

	func _init(position_p : Vector2i):
		position = position_p
