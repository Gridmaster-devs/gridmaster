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

var stopped : bool = false

# Which tile our unit is currently on (index of path)
var current_tile : int = 0

# How much movement the unit has built up for movement
var built_up_movement : int = 0

# Which tile we'd like to move to (index of path)
var skip_tile_count : int = 0

var cumulative_movement_cost : int = 0

# What's the last tile on the path (index of path)
var last_tile : int


## Tries to move the unit one step forward when called
func step() -> void:
	# We have already stopped
	if (stopped == true): return
	
	# Increement movement
	built_up_movement += 1
	
	var next_tile_index = current_tile + skip_tile_count + 1
	
	# We can't move this far
	if next_tile_index > last_tile:
		stopped = true
		return
	
	var next_tile = _game_state.getGameGrid().get_tile_vec(path[next_tile_index])
	var movement_req : int = next_tile.getTileType().get_attribute(TileType.TILE_ATTRIBUTE_TYPE.MOVEMENT)
	
	# Unit does not have enough movement to move to the tile
	if (movement_req + cumulative_movement_cost > built_up_movement): return
	
	# If there is a unit on the next tile
	var tile_unit = next_tile.get_first_unit()
	if (tile_unit != null):
		
		# If the unit is an enemy unit
		if (tile_unit.team_id != unit.team_id):
			
			# We can't fight an enemy unit if it's more than one tile away
			if (skip_tile_count > 0):
				stopped = true
				return
			
			# Fight the enemy unit
			else:
				GameState.fight_func.call(unit, tile_unit)
				
				# Our unit died
				if unit.is_dead():
					stopped = true
					return
				
				# Our unit survived
				else:
					# Enemy unit died
					if (tile_unit.is_dead()):
						
						# We should stop after fighting
						if (_stop_after_fighting == true):
							_game_state.move_unit(unit.getId(), tile_unit.getPosition())
						
						# We should not stop after fighting
						else:
							return
					
					# Enemy unit survived
					else:
						stopped = true
						return
				
		
		# If the unit is an allied unit
		elif (tile_unit.team_id == unit.team_id):
			
			# Unit will not be moving anymore so we'll try to see if the next tile
			# past the unit is valid and move there
			if tile_unit.has_stopped():
				skip_tile_count += 1
				cumulative_movement_cost += movement_req
				return
			
			# We will wait for the unit to move
			else:
				return
		
	# Nothing prevents us from moving
	
	_game_state.move_unit(unit.getId(), path[next_tile_index])
	current_tile = next_tile_index
	built_up_movement -= cumulative_movement_cost + movement_req
	cumulative_movement_cost = 0
	skip_tile_count = 0
	


func execute():
	_game_state.move_unit(unit.getId(), path.back())


func movement_target() -> Vector2i:
	return path.back()


func _init(path_p : Array[Vector2i], p_id : int, unit_p : Unit, game_state_p : GameState):
	path = path_p
	player_id = p_id
	unit = unit_p
	last_tile = path.size() - 1
	_game_state = game_state_p
