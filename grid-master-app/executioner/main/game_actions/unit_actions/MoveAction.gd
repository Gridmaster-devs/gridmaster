class_name MoveAction
extends UnitAction
## An action that represents a unit moving from place A to place B

## Path of nodes the unit is set to travel.
## The first item is always the starting position of the unit,
## and the last item is always the final position of the unit.

var path : Array[Vector2i]

var searching_next_tile : bool = false

# Whether we have stopped moving
var stopped : bool = false

# Which tile our unit is currently on (index of path)
var current_tile : int = 0

# How much movement the unit has built up for movement
var built_up_movement : int = 0

# What's the last tile on the path (index of path)
var last_tile : int

# What unit we would like to swap with
var swap_suggested_unit : int = -1

# How much movement the swap would cost
var swap_movement_cost : int = 0

# How many tiles forward the swap would move us
var swap_distance : int = 0



# Which units we have fought during this movement
# Stored so we don't fight the same unit again
var units_fought : Dictionary[int, bool] = {}


func stop() -> void:
	stopped = true
	swap_suggested_unit = -1


## Lets the move action know we have been in a battle
##
## Only to be called by the fight function
func fought(enemy_unit_id : int):
	units_fought.set(enemy_unit_id, true)
	if (GameArgs.stop_after_fighting == true):
		stop()


func handle_swap() -> void:
	current_tile += swap_distance
	built_up_movement -= swap_movement_cost
	reset_swap()


func reset_swap() -> void:
	swap_distance = 0
	swap_movement_cost = 0
	swap_suggested_unit = -1


## Tries to move the unit one step forward when called
func step() -> void:
	var loops = 0
	# We have already stopped
	if (stopped == true): return
	
	# Increment movement
	built_up_movement += 1
	var movement_req : int = 0
	
	# keep looping tiles until we run out of movement, fight, or go beyond our last tile
	while(true):
		
		var next_tile_index = current_tile + 1 + loops
		
		# We can't move this far
		if next_tile_index > last_tile:
			stopped = true
			return
		
		var next_tile = _game_state.getGameGrid().get_tile_vec(path[next_tile_index])
		
		# Add next tile to movement requirements
		movement_req += next_tile.getTileType().get_attribute(TileType.TILE_ATTRIBUTE_TYPE.MOVEMENT)
		
		# Unit does not have enough movement to move to the tile
		if (movement_req > built_up_movement): return
		
		# Check if there is a unit on the tile we're trying to move to
		var unit_on_tile : Unit = next_tile.get_unit()
		
		# There is a unit on the next tile we want to move to:
		if unit_on_tile != null:
			
			# the unit on the tile is an enemy unit
			if (unit_on_tile.get_team_id() != unit.get_team_id()):
				
				# We've already fought the unit on the tile
				# so we'll try to move past it
				if (units_fought.get(unit_on_tile.unit_id, false) == true):
					loops += 1
					continue
				
				# We haven't fought the unit on the tile yet
				else:
					# We can't fight a unit that's not right next to us
					# There are so many possible edge cases so we'll just call it and stop
					if (loops > 0):
						stopped = true
						return
					
					# Fight the unit
					var fight_func = GameState.game_args.args.get(GameArgs.ArgType.FIGHT_FUNC)
					fight_func.call(unit, unit_on_tile)
					
					# Make sure they won't fight us again
					unit_on_tile.set_fought(unit.unit_id)
					
					# TODO: Replace this with logic that moves the unit to the path
					# of the fought unit if the enemy unit died in the fight and we didn't
					
					# One way to do this would be to replace the movement path with one that begins
					# on our current square and ends on the enemy's tile
					
					# Whether we stop after fighting or not
					if (GameArgs.stop_after_fighting == true):
						# We do stop
						stopped = true
						return
					
					else:
						# We don't stop
						return
					
			
			# The unit on the tile is a friendly unit
			else:
				# Unit on the tile is trying to move onto our tile
				if (unit_on_tile.get_next_movement_tile() == unit.grid_position):
					
					# We see if they've suggested a swap with us
					if (unit_on_tile.get_swap_suggested_unit() == unit.unit_id):
						
						# They have
						swap_movement_cost = movement_req
						swap_distance = 1 + loops
						_game_state.swap_units(unit, unit_on_tile)

					else:
						# They haven't
						swap_movement_cost = movement_req
						swap_distance = 1 + loops
						swap_suggested_unit = unit_on_tile.unit_id
				
				# They're not trying to move onto our tile
				else:
					loops += 1
					continue
		
		else:
			# There is nothing on the tile and
			# nothing prevents us from moving
			
			_game_state.move_unit(unit.getId(), path[next_tile_index])
			current_tile = next_tile_index
			built_up_movement -= movement_req
			reset_swap()
	


func execute():
	_game_state.move_unit(unit.getId(), path.back())


func movement_target() -> Vector2i:
	return path.back()


# This is jank and I imagine could fail easily
func next_movement_tile() -> Vector2i:
	if (stopped == true):
		return path[current_tile]
	else:
		searching_next_tile = true
		
		var tile_index = current_tile
		while(true):
			
			tile_index += 1
			
			# Ran out of tiles, we'll return our current tile
			if (tile_index > last_tile):
				searching_next_tile = false
				return path[current_tile]
			
			var tile = _game_state.getGameGrid().get_tile_vec(path[tile_index])
			var tile_unit = tile.get_unit()
			
			# If there is no unit on the tile we try to move to it
			if (tile_unit == null):
				break
			
			# If there is a unit on the tile we will see what happens
			else:
				# Friendly unit
				if (tile_unit.get_team_id() == unit.get_team_id()):
					
					# They are also searching with this function which means they are
					# trying to move, so we will try to move to this tile
					if (tile_unit.searching_next_tile()):
						break
					
					# They are trying to move to our tile, so we can swap
					elif (tile_unit.get_next_movement_tile() == unit.grid_position):
						break
					
					# They have stopped or are trying to move somewhere else
					else:
						continue
				
			
		
		searching_next_tile = false
		return path[tile_index]


func _init(path_p : Array[Vector2i], p_id : int, unit_p : Unit, game_state_p : GameState):
	path = path_p
	player_id = p_id
	unit = unit_p
	last_tile = path.size() - 1
	_game_state = game_state_p
