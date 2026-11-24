class_name DeveloperCommands
extends RefCounted
## Shared result format and spawn validation for the local game and server.


static func result(code: String, message: String, data: Dictionary = {}) -> Dictionary:
	return {"ok": code == "ok", "code": code, "message": message, "data": data}


static func spawn(
	manager: GameDataManager, game_over: bool, player: Player,
	type_name: String, x: int, y: int
) -> Dictionary:
	if game_over:
		return result("game_over", "The match has ended.")
	var unit_type: UnitType
	for registered_type: UnitType in manager.get_game_defintion().unit_types.values():
		if registered_type.unit_name == type_name:
			unit_type = registered_type
			break
	if unit_type == null:
		return result("unknown_unit_type", 'Unknown unit type "%s". See types.' % type_name)
	var grid: GameGrid = manager.get_grid()
	# Check before converting to Vector2i, whose coordinates are 32-bit.
	if x < 0 or x >= grid.width or y < 0 or y >= grid.height:
		return result("out_of_bounds", "Tile (%d, %d) is outside the map." % [x, y])
	var tile := Vector2i(x, y)
	if manager.get_unit_by_position_nullable(tile) != null:
		return result("occupied", "Tile (%d, %d) is occupied." % [x, y])
	var unit: Unit = manager.add_unit(unit_type, tile, player)
	return result("ok", 'Spawned "%s" at (%d, %d) with unit ID %d.' % [
		type_name, x, y, unit.getId(),
	], {"unit_id": unit.getId()})
