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

func get_unit_by_position_nullable(pos: Vector2i) -> Unit:
	return _game_state.get_unit_by_position_nullable(pos)

func get_grid() -> GameGrid:
	return _game_definition.grid
	
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
