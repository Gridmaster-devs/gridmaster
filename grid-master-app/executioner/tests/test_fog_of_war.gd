extends GutTest

var game_state : GameState
var game_master : GameMaster
var game_grid: GameGrid
var player_1_id: int
var player_2_id: int
var enemy_player_id: int


func before_each():
	game_state = GameState.new()
	game_master = GameMaster.new()
	game_grid = GameGrid.new(10, 10)
	game_state._grid = game_grid
	game_master.game_state = game_state
	
	# Setup grid with tiles
	var fill_func = func(_x, _y):
		return GridTile.new(TileType.new(), Vector2i(_x, _y))
	game_grid.fillTiles(fill_func)
	
	#Add teams and players
	var team_1_id: int = game_state.add_team("Team 1", Color(0, 0, 0), [])
	player_1_id = game_state.add_player("Player 1", team_1_id, false)
	player_2_id = game_state.add_player("Player 2", team_1_id, false)
	var enemy_team_id: int = game_state.add_team("Enemy team", Color(0, 0, 0), [])
	enemy_player_id = game_state.add_player("Enemy player", enemy_team_id, false)
	game_state.client_player_id = player_1_id
	

func after_each():
	game_state = null
	game_master = null


#Helper function to add units to the game state
func add_unit(player_id: int, pos: Vector2i, vision_range:= 1) -> Unit:
	var unit_type: UnitType = UnitType.new()
	#Create unit attributes
	var attributes: Dictionary[UnitType.UNIT_ATTRIBUTE_TYPE, Variant] = {}
	attributes[UnitType.UNIT_ATTRIBUTE_TYPE.MAX_HP] = 10
	attributes[UnitType.UNIT_ATTRIBUTE_TYPE.INITIAL_MORALE] = 5
	attributes[UnitType.UNIT_ATTRIBUTE_TYPE.MOVEMENT_SPEED] = 2
	attributes[UnitType.UNIT_ATTRIBUTE_TYPE.VISION_RANGE] = vision_range
	unit_type.attributes = attributes
	
	#Add the unit to the game state
	return game_state.addUnit(unit_type, pos, player_id)

#Test that own units always appear visible
func test_own_units_always_visible():
	var client_id: int = game_state.get_client_player_id()
	#Add a few units 
	add_unit(client_id, Vector2i(0, 0))
	add_unit(client_id, Vector2i(1, 0))
	add_unit(client_id, Vector2i(1, 1))
	
	var visible: Variant = game_master.get_visible_units()
	
	for unit in game_state.getUnits():
		if unit.get_player_id() == client_id:
			assert_true(unit in visible, "Own unit should be in visible units")

#Test that teammates units are always visible
func test_teammate_units_visible():
	var client_team_id: int = game_state.players.get(game_state.get_client_player_id()).team.team_id
	#Add a few units 
	add_unit(player_2_id, Vector2i(0, 0))
	add_unit(player_2_id, Vector2i(1, 0))
	add_unit(player_2_id, Vector2i(1, 1))
	
	var visible: Variant = game_master.get_visible_units()
	
	for unit in game_state.getUnits():
		if unit.get_team_id() == client_team_id:
			assert_true(unit in visible, "Teammate unit should be in visible units")



#Fills the grid with enemy units and tests whether each unit is inside vision range or not
func test_visibility():
	var vision: int = 3
	#Add a unit to player 1
	var unit_pos = Vector2i(5, 5)
	add_unit(player_1_id, unit_pos, vision)
	
	var width: int = game_grid.getWidth()
	var height: int = game_grid.getHeight()
	#Fills each grid with an enemy unit
	for i in range(width):
		for j in range(height):
			#Ignore tile with player 1 unit
			if i == unit_pos.x and j == unit_pos.y:
				continue
			var enemy_pos = Vector2i(i, j)
			var enemy_unit: Unit = add_unit(enemy_player_id, enemy_pos)
			var visible: Variant = game_master.get_visible_units()
			var dx: int = abs(unit_pos.x - enemy_pos.x)
			var dy: int = abs(unit_pos.y - enemy_pos.y)
			#Checks if enemy is within vision range
			if max(dx, dy) <= vision:
				assert_true(enemy_unit in visible, "Enemy at %s should be visible" % str(enemy_pos))
			else:
				assert_false(enemy_unit in visible, "Enemy at %s should not be visible" % str(enemy_pos))
				
