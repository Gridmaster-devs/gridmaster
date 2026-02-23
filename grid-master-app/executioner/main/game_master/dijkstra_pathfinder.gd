class_name DijkstraPathfinder
extends RefCounted

# NOTE: If this is too slow it can be rewritten in a high-performance language 

# Largest number an int can store, acting as infinity here
const MAX_INT : int = 9223372036854775807

var _djikstra_grid : Array[DijkstraNode] # Array of Dijkstra nodes
var _game_grid : GameGrid # Array of tiles as in the gamestate
var _units : Dictionary[int, Unit] # Array of units as in the gamestate
var _grid_width : int
var _grid_height : int


## Initializes the Djikstra Pathfinder's grid from a game_grid.
## Only needs to be called once when a game is started.
func initialize(game_grid : GameGrid, units : Dictionary[int, Unit]) -> void:
	assert(game_grid != null, "Tried giving null game grid to Djikstra Pathfinder!")
	_units = units
	_game_grid = game_grid
	_grid_width = _game_grid.getWidth()
	_grid_height = _game_grid.getHeight()

	for y in range(0, _grid_height):
		for x in range(0, _grid_width):
			_djikstra_grid.append(DijkstraNode.new(Vector2i(x, y)))

	update_grid()


func get_node_vec(pos : Vector2i):
	return _djikstra_grid[_grid_width * pos.y + pos.x]
	
func get_node(x : int, y : int):
	return _djikstra_grid[_grid_width * y + x]

func get_index(x : int, y : int):
	return (_grid_width * y + x)

func get_index_vec(pos : Vector2i):
	return (_grid_width * pos.y + pos.x)


## Updates the values of the tiles on the grid.
## Call if grid tile movement values change.
func update_grid() -> void:
	for y in range(0, _grid_height):
		for x in range(0, _grid_width):
			var tile_type : TileType = _game_grid.getTileType(x, y)
			var node : DijkstraNode = get_node(x, y)
			node.movement = tile_type.get_attribute(TileType.TILE_ATTRIBUTE_TYPE.MOVEMENT)


func _get_neighbors(node : DijkstraNode) -> Array[int]:
	var neighbors : Array[int] = []
	var x = node.position.x
	var y = node.position.y
	
	if (x > 0):
		neighbors.append(get_index(x-1,y))
	
	if (x < _grid_width - 1):
		neighbors.append(get_index(x+1,y))
	
	if (y > 0):
		neighbors.append(get_index(x,y-1))
	
	if (y < _grid_height - 1):
		neighbors.append(get_index(x,y+1))
	
	return neighbors


func _reset_nodes() -> void:
	var reset_func = func(node : DijkstraNode):
		node.movement_required = MAX_INT
		node.enqueued = false
		node.previous = null
		node.possible = false
		node.has_unit = false
		node.movement_target = false
	
	for node : DijkstraNode in _djikstra_grid:
		reset_func.call(node)
		if (!_game_grid.is_empty(node.position)): node.has_unit = true
	
	var action : GameAction
	for unit : Unit in _units.values():
		action = unit.current_action
		if action is MoveAction:
			var pos = action.movement_target()
			get_node_vec(pos).movement_target = true


## Returns an array of all tiles that are possible to reach from
## the starting position with a set amount of movement
func tiles_from_position(start_position : Vector2i, movement_available : int) -> Array[Vector2i]:
	var unvisited := DijkstraPriorityQueue.new()
	var possible : Array[Vector2i] = [] # Possible to reach tiles
	_reset_nodes() # Reset the nodes from a previous calculation
	
	
	var start_node : DijkstraNode = get_node_vec(start_position)
	start_node.movement_required = 0
	unvisited.add_item(Vector2(0, get_index_vec(start_position)))
	
	var count : int = 0
	
	var current_vec2 : Vector2
	var current_node : DijkstraNode
	var neighbor_node : DijkstraNode
	while(true):
		# Get the unvisited node with the lowest movement required
		
		count += 1
		
		current_vec2 = unvisited.pop_first()
		if (current_vec2 == Vector2(-1, -1)):
			break
		
		# There is a node to process
		else:
			current_node = _djikstra_grid[int(current_vec2.y)]
			current_node.enqueued = true
			
			# If our unit has enough movement to reach this tile, there are no units on the tile yet, and no other unit plans to move onto the tile
			if ((current_node.movement_required <= movement_available and !current_node.has_unit and !current_node.movement_target) or (current_node.position == start_position)):
				if current_node.position != start_position: # We don't want to add the start position to the possible moves
					possible.append(current_node.position)
					current_node.possible = true
				
				var neighbors = _get_neighbors(current_node)
				
				for index : int in neighbors:
					neighbor_node = _djikstra_grid[index]
					neighbor_node.update_movement_req(current_node)
					if (neighbor_node.enqueued == false):
						neighbor_node.enqueued = true
						unvisited.add_item(Vector2(neighbor_node.movement_required, get_index_vec(neighbor_node.position)))
					
	return possible


func movement_required_to_position(pos : Vector2i):
	var tile : DijkstraNode = get_node_vec(pos)
	return tile.movement_required


## Returns a path from a previously calculated starting position
## (with tiles_from_position), if it exists
func get_path_to_pos(position : Vector2i) -> Array[Vector2i]:
	var path : Array[Vector2i] = []
	
	var current_node : DijkstraNode = get_node_vec(position)
	if current_node.possible == false:
		return []

	while(true):
		path.append(current_node.position)
		current_node = current_node.previous
		if current_node == null: break
	
	# If path would only have the beginning position we return an empty array instead
	# don't think this is required anymore
	if (path.size() <= 1):
		return []
	else:
		return path



## Class that represents a node in the pathfinder.
class DijkstraNode extends RefCounted:
	
	var position : Vector2i
	var movement : int = 1 # movement required to move onto the node from a neighbor
	var possible : bool = false
	var has_unit : bool = false
	var movement_target : bool = false
	
	var enqueued : bool = false
	var previous : DijkstraNode = null
	
	# movement required to move to the node from the beginning node
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


class DijkstraPriorityQueue extends RefCounted:
	## Simple priority queue implementation

	# Highest priority (lowest priority value) is always the last element
	# in the array. The array is always sorted.
	var _items : PackedVector2Array = []

	func add_item(item : Vector2):
		# If there are no items in the array we can just put the item in
		if (_items.is_empty()):
			_items.append(item)

		# If there are items in the array, we must keep the array sorted
		# We find the first element with a priority
		else:
			var pos : int = _items.bsearch(item)
			_items.insert(pos, item)

	## Returns and removes the item with the lowest priority value from the queue.
	func pop_first() -> Vector2:
		if _items.is_empty():
			return Vector2(-1, -1)
		else:
			var elem : Vector2 = _items[0]
			_items.remove_at(0)
			return elem


	## Returns the number of items in the queue.
	func item_count() -> int:
		return _items.size()


	## The priority func must return an int when fed
	## an object of the stored type.
	func _init() -> void:
		pass
