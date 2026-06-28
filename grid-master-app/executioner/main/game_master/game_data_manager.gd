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

## meant mainly for internal consumption now, use [method GameDataManager.initFromGameDefinition]
func _init(game_state: GameState, game_definition: GameDefinition, client_attributes: ClientAttributes) -> void:
	_game_state = game_state
	_game_definition = game_definition
	_client_attributes = client_attributes

## Initializes game state, game definition and pathfinder objects and assigns them to the respective member variables.
## NOTE that the game definition object initialized here ([GameDefinition]) is a distinct type and concept from [GameDefinitionResource].
static func initFromGameDefinition(game_definition_resource : GameDefinitionResource) -> GameDataManager:
	## Initialize new game data objects
	var unit_name_type_dict: Dictionary[String, int] = {}
	var new_game_state = GameState.new({}, 0, 0)
	var new_game_definition = GameDefinition.new()
	var new_client_attributes = ClientAttributes.new()
	new_game_definition.initUnitTypesFromResource(game_definition_resource, unit_name_type_dict)
	new_game_definition.game_name = game_definition_resource.game_name
	new_game_definition._grid = GameGrid.initFromMapResource(game_definition_resource.loadMap())
	
	var game_def_teams: Array[TeamUiRes] = game_definition_resource.team_uis
	var game_def_players: Array[PlayerUiRes] = game_definition_resource.player_uis
	
	
	var team_id_dict: Dictionary[String, int] = {}
	
	var player_name_id_dict: Dictionary[String, int] = {}
	#teams and players
	for team in game_def_teams: 
		var team_name = team.get_team_name()
		var unit_names: Dictionary[String, bool] = team.get_units()
		var team_units: Array[UnitType] = []
		for unit_name in unit_names.keys(): 
			if unit_names[unit_name]:
				var cur_unit_type_id = unit_name_type_dict[unit_name]
				team_units.append(new_game_definition.unit_types[cur_unit_type_id])
		var team_id = new_game_definition.add_team(team_name, team.get_team_color(), team_units)
		team_id_dict[team_name] = team_id
	
	var client_player_added: bool = false
	for player in game_def_players: 
		var player_team = null
		var ptdict = player.get_teams()
		var player_name = player.get_player_name()
		#get the team of the player
		for t_name in ptdict.keys():
			if ptdict[t_name]:
				player_team = t_name
		if player_team == null:
			continue
		#add the player 
		var p_id = new_game_definition.add_player(player_name, team_id_dict[player_team], false)
		player_name_id_dict[player_name] = p_id
		#add the client player as the first one
		if !client_player_added: 
			new_client_attributes.client_player_id = p_id
			client_player_added = true
	
	#units on the map
	var unit_layer = game_definition_resource.unit_layer
	for x in unit_layer.width:
		for y in unit_layer.height:
			var cur_attributes = unit_layer.getItem(x, y)
			if (cur_attributes.has(MapAttributes.UNIT_UNIT_LIB_ITEM_ID) and 
				cur_attributes.has(MapAttributes.UNIT_TEAM_ID) and 
				cur_attributes.has(MapAttributes.UNIT_PLAYER_ID)):
				var unit_name = cur_attributes[MapAttributes.UNIT_UNIT_LIB_ITEM_ID]
				var player_name = cur_attributes[MapAttributes.UNIT_PLAYER_ID]
				new_game_state.addUnit(new_game_definition.unit_types.get(unit_name_type_dict[unit_name]), Vector2i(x, y), new_game_definition.get_player_by_id(player_name_id_dict[player_name])) # FIXME redundant way to get unittype in first argument 

	# Initialize GameDataManager with initialized game data objects
	return GameDataManager.new(new_game_state, new_game_definition, new_client_attributes)

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
	 
func get_teams() -> Dictionary[int, Team]:
	return _game_definition.teams
	
func get_players() -> Dictionary[int, Player]:
	return _game_definition.players
	
func get_client_player_id() -> int:
	return _client_attributes.client_player_id
	
func get_turn_number() -> int:
	return _game_state._turn_number

# Returns all units currently visible from the perspective of the client player
func get_visible_units() -> Array[Unit]:
	if _game_state == null:
		return []
	
	var visible_units: Array[Unit] = []
	# Use the pov of the client player
	var client_player_id: int = _client_attributes.client_player_id
	var client_player: Player =  _game_definition.players.get(client_player_id)
	
	if client_player == null:
		return []
	
	var client_team_id: int = client_player.team.team_id
	# Goes over each unit in the game and checks whther the client player sees it or not
	for unit in _game_state.getUnits():
		print(unit.type.producible_units_ids)
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
	
func get_unit_by_id(id: int) -> Unit:
	return _game_state.get_unit_by_id(id)

func get_grid() -> GameGrid:
	return _game_definition.grid

# Used for visibility logic. Checks if the target unit is visible to the given player
## TODO probably should not be here, could be moved to Team if the team knows its own units
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

func move_unit(unit_id : int, new_position : Vector2i) -> void:
	_game_state.move_unit(unit_id, new_position)

## Replace entire game state with new instance
func replace_game_state(new_game_state: GameState) -> void:
	_game_state = new_game_state

func increment_turn_number() -> void:
	_game_state.increment_turn_number()

func remove_unit(unit: Unit) -> void:
	_game_state.remove_unit(unit)

func add_unit(unit_type : UnitType, position : Vector2i, player : Player) -> void:
	_game_state.addUnit(unit_type, position, player)
