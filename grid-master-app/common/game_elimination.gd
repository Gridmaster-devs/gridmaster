class_name GameElimination
extends RefCounted
## Shared win/lose rules: a player is eliminated when they have no living key units.


static func is_active_player(player_id: int) -> bool:
	return player_id > 0


static func player_has_key_units(player: Player, units: Dictionary) -> bool:
	if player.key_unit_type == null:
		return _player_has_any_living_units(player.player_id, units)
	for unit: Unit in units.values():
		if unit.player.player_id != player.player_id:
			continue
		if unit.is_dead():
			continue
		if unit.type.unit_name == player.key_unit_type.unit_name:
			return true
	return false


static func _player_has_any_living_units(player_id: int, units: Dictionary) -> bool:
	for unit: Unit in units.values():
		if unit.player.player_id == player_id and not unit.is_dead():
			return true
	return false


static func get_newly_eliminated(players: Dictionary, units: Dictionary, already_eliminated: Array[int]) -> Array[int]:
	var newly_eliminated: Array[int] = []
	for player_id in players.keys():
		if not is_active_player(player_id):
			continue
		if already_eliminated.has(player_id):
			continue
		var player: Player = players[player_id]
		if not player_has_key_units(player, units):
			newly_eliminated.append(player_id)
	return newly_eliminated


static func get_players_with_key_units(players: Dictionary, units: Dictionary, eliminated: Array[int]) -> Array[int]:
	var alive: Array[int] = []
	for player_id in players.keys():
		if not is_active_player(player_id):
			continue
		if eliminated.has(player_id):
			continue
		if player_has_key_units(players[player_id], units):
			alive.append(player_id)
	return alive


static func get_winner_player_id(players: Dictionary, units: Dictionary, eliminated: Array[int]) -> int:
	var alive := get_players_with_key_units(players, units, eliminated)
	if alive.size() == 1:
		return alive[0]
	return -1
