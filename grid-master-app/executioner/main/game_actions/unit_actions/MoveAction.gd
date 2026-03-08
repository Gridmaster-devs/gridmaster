class_name MoveAction
extends UnitAction
## An action that represents a unit moving from place A to place B

## Path of nodes the unit is set to travel.
## The first item is always the starting position of the unit,
## and the last item is always the final position of the unit.
const FLAG_STOP_AFTER_FIGHTING : int = 1

static var _stop_after_fighting : bool = true

static func set_flags(flags : int):
	if (flags & FLAG_STOP_AFTER_FIGHTING > 0):
		_stop_after_fighting = true
	else:
		_stop_after_fighting = false
	

var path : Array[Vector2i]

# Whether we have stopped moving
var stopped : bool = false

# Which tile our unit is currently on (index of path)
var current_tile : int = 0

# How much movement the unit has built up for movement
var built_up_movement : int = 0

# What's the last tile on the path (index of path)
var last_tile : int

# Which units we have fought during this movement
# Stored so we don't fight the same unit again
var units_fought : Dictionary[int, bool] = {}


## Tries to move the unit one step forward when called
func step() -> void:
	# We have already stopped
	if (stopped == true): return
	
	# Increment movement
	built_up_movement += 1
	
	var next_tile_index = current_tile + 1
	
	# We can't move this far
	if next_tile_index > last_tile:
		stopped = true
		return
	
	var next_tile = _game_state.getGameGrid().get_tile_vec(path[next_tile_index])
	var movement_req : int = next_tile.getTileType().get_attribute(TileType.TILE_ATTRIBUTE_TYPE.MOVEMENT)
	
	# Unit does not have enough movement to move to the tile
	if (movement_req > built_up_movement): return
	
	var unit_on_tile = next_tile.get_first_unit()
	
	# There is a unit on the next tile we want to move to:
	if unit_on_tile != null:
		
		if (unit_on_tile):
			pass
		
	
	
	# Nothing prevents us from moving
	
	_game_state.move_unit(unit.getId(), path[next_tile_index])
	current_tile = next_tile_index
	


func execute():
	_game_state.move_unit(unit.getId(), path.back())


func movement_target() -> Vector2i:
	return path.back()


func next_movement_tile() -> Vector2i:
	if (stopped == true):
		return path[current_tile]
	else:
		# This should never return anything out of bounds because a unit
		# should always stop
		return path[current_tile + 1]


func _init(path_p : Array[Vector2i], p_id : int, unit_p : Unit, game_state_p : GameState):
	path = path_p
	player_id = p_id
	unit = unit_p
	last_tile = path.size() - 1
	_game_state = game_state_p
