class_name ProductionAction
extends UnitAction
# An action that produces a unit on the map

# The unit that will be produced
var producible_unit: UnitType

# The turns remaining until the unit is produced
var remaining_turns: int

# Whether the action is finished
var finished: bool = false

## Progress of the production in percentage (0.0 to 1.0)
var progress: float:
	get:
		return (1.0 - float(remaining_turns) / float(producible_unit.production_cost))

# The main function which is called every turn and produces a unit at the end
func handle_turn():
	remaining_turns -= 1
	
	if remaining_turns == 0:
		_finish_production()
		GML.log("[Unit %s] finished producing [%s]" % [unit.unit_id, producible_unit.unit_name], GML.LogLevel.DEBUG)
	else:
		MessageDispatcher.broadcast_message("[Unit %s] producing [%s] (%s turns remaining)" % [unit.unit_id,
		producible_unit.unit_name, remaining_turns])
		GML.log("[Unit %s] producing [%s] (%s turns remaining)" % [unit.unit_id, producible_unit.unit_name, remaining_turns], GML.LogLevel.DEBUG)


# Finishes production of the unit and places it on the map
func _finish_production():
	var producible_unit_pos: Variant = null
	var producing_unit_pos: Vector2i = unit.getPosition()
	var direction: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(0, 1),
		Vector2i(-1, 0),
		Vector2i(0, -1)
	]
	
	# Try different tiles near unit
	for dir in direction:
		var new_pos: Vector2i = producing_unit_pos + dir
		if _is_valid_spawn_pos(new_pos):
			producible_unit_pos = new_pos
	
	# Produce unit and inform player
	if producible_unit_pos != null:
		_game_data_provider.add_unit(producible_unit, producible_unit_pos, unit.player)
		MessageDispatcher.broadcast_message("[Unit %s] produced [Unit %s]" % [unit.unit_id,
		_game_data_provider.get_game_state().getUnits().back().getId()])
	else:
		# If there is no free tiles near the unit, production fails
		MessageDispatcher.broadcast_message("[Unit %s] failed to produce [%s]" % [unit.unit_id, producible_unit.unit_name])
	
	finished = true


# Helper function to check if a given position is valid
func _is_valid_spawn_pos(pos: Vector2i) -> bool:
	if not _game_data_provider._game_definition.getGameGrid().is_in_bounds(pos):
		return false
	
	if not _is_tile_free(pos):
		return false
	
	return true


# Helper function to the check if given tile position is free of units
func _is_tile_free(pos: Vector2i) -> bool:
	var units: Array[Unit] = _game_data_provider.get_game_state().getUnits()
	for unit_l in units:
		if unit_l.getPosition() == pos:
			return false
	
	return true

func is_interruptible() -> bool:
	return false


func deep_copy(new_unit: Unit) -> ProductionAction:
	var copy = ProductionAction.new(player_id, new_unit, _game_data_provider, producible_unit)
	copy.remaining_turns = self.remaining_turns
	
	return copy

func _init(p_id : int, unit_p : Unit, game_data_provider: GameDataManager, producible_unit_p: UnitType):
	player_id = p_id
	unit = unit_p
	_game_data_provider = game_data_provider
	producible_unit = producible_unit_p
	remaining_turns = producible_unit.production_cost
