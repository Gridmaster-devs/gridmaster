class_name MoveAction
extends UnitAction
## An action that represents a unit moving from place A to place B

## Path of nodes the unit is set to travel.
## The first item is always the starting position of the unit,
## and the last item is always the final position of the unit.
var path : Array[Vector2i]

var stopped : bool = false

# Which tile our unit is currently on (index of path)
var current_tile : int = 0

var built_up_movement : int = 0

# Which tile we'd like to move to (index of path)
var skip_tile_count : int = 0

# What's the last tile on the path (index of path)
var last_tile : int

func step() -> void:
	pass


func execute(game_state : GameState):
	game_state.move_unit(unit.getId(), path.back())


func movement_target() -> Vector2i:
	return path.back()


func _init(path_p : Array[Vector2i], p_id : int, unit_p : Unit):
	path = path_p
	player_id = p_id
	unit = unit_p
	last_tile = path.size() - 1
