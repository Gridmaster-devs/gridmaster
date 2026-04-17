class_name GameDataManager
extends RefCounted
## Manages game data that is made up of GameState, GameDefinition, and ClientAttributes objects.
## Inject as dependency to classes that need read access to game data. Instead of
## reusing or storing references to GameState etc. in your calling class, please
## only store a reference to GameDataManager and call its methods to avoid stale
## references.
## Mutating methods are supposed to be called only by GameMaster.

var _game_state: GameState
var _game_definition: GameDefinition
var _client_attributes: ClientAttributes

func _init(game_state: GameState, game_definition: GameDefinition, client_attributes: ClientAttributes) -> void:
	_game_state = game_state
	_game_definition = game_definition
	_client_attributes = client_attributes

# ---
# INFO read-only methods
# ---

func get_game_state() -> GameState:
	return _game_state
	
func get_game_defintion() -> GameDefinition:
	return _game_definition

func get_client_attributes() -> ClientAttributes:
	return _client_attributes
	
func get_game_name() -> String:
	return _game_definition.game_name
	
func get_units() -> Dictionary[int, Unit]:
	return _game_state._units

# Returns all units currently visible from the perspective of the client player
func get_visible_units() -> Variant:
	if _game_state == null:
		return null
	
	var visible_units: Array[Unit] = []
	# Use the pov of the client player
	var client_player_id: int = _client_attributes.client_player_id
	var client_player: Player =  _game_definition.players.get(client_player_id)
	
	if client_player == null:
		return []
	
	var client_team_id: int = client_player.team.team_id
	# Goes over each unit in the game and checks whther the client player sees it or not
	for unit in _game_state.getUnits():
		var unit_team_id: int = unit.get_team_id()
		
		# Always sees units on the same team
		if unit_team_id == client_team_id:
			visible_units.append(unit)
		elif _is_unit_visible(unit, client_player_id):
			visible_units.append(unit)
		
	return visible_units

func get_unit_by_position_nullable(pos: Vector2i) -> Unit:
	return _game_state.get_unit_by_position_nullable(pos)

func get_grid() -> GameGrid:
	return _game_definition.grid

# Used for visibility logic. Checks if the target unit is visible to the given player
## TODO probably should not be here, could be moved to Player if the player knows its own units
func _is_unit_visible(target_unit: Unit, player_id: int) -> bool:
	var player: Player = _game_definition.players.get(player_id)
	
	if player == null:
		return false
	
	var team_id: int = player.team.team_id
	
	# Check visibility against all units owned by the same team
	for unit in _game_state.getUnits():
		if unit.get_team_id() == team_id:
			# Compute using Chebyshev distance
			var dx: int = abs(unit.getPosition().x - target_unit.getPosition().x)
			var dy: int = abs(unit.getPosition().y - target_unit.getPosition().y)
			
			# If the target is within vision range of this unit means it is visible 
			if max(dx, dy) <= unit.vision_range:
				return true
		
	return false
	
# ---
# INFO mutating methods
# ---

## Replace entire game state with new instance
func replace_game_state(new_game_state: GameState) -> void:
	_game_state = new_game_state

func increment_turn_number() -> void:
	_game_state.increment_turn_number()

func remove_unit(unit: Unit) -> void:
	_game_state.remove_unit(unit)
