extends GutTest

var game_state : GameState
var game_def: GameDefinition
var game_manager: GameDataManager
var client_attributes: ClientAttributes
var game_grid: GameGrid
var player_1_id: int
var player_2_id: int
var enemy_player_id: int


func before_each():
	game_state = GameState.new({}, 0, 0)
	game_grid = GameGrid.new(10, 10)
	game_def = GameDefinition.new()
	client_attributes = ClientAttributes.new()
	game_manager = GameDataManager.new(game_state, game_def, client_attributes)
	game_def._grid = game_grid
	
	# Setup grid with tiles
	var fill_func = func(_x, _y):
		return GridTile.new(TileType.new(), Vector2i(_x, _y))
	game_grid.fillTiles(fill_func)
	
	#Add teams and players
	var team_1_id: int = game_def.add_team("Team 1", Color(0, 0, 0), [])
	player_1_id = game_def.add_player("Player 1", team_1_id, false)
	player_2_id = game_def.add_player("Player 2", team_1_id, false)
	var enemy_team_id: int = game_def.add_team("Enemy team", Color(0, 0, 0), [])
	enemy_player_id = game_def.add_player("Enemy player", enemy_team_id, false)
	client_attributes.client_player_id = player_1_id
	


#Helper function to add units to the game state
func add_unit(player_id: int, pos: Vector2i, vision_range:= 1) -> Unit:
	var player: Player = game_def.players.get(player_id)
	var unit_type: UnitType = UnitType.new()
	#Create unit attributes
	var attributes: Dictionary[UnitType.UNIT_ATTRIBUTE_TYPE, Variant] = {}
	attributes[UnitType.UNIT_ATTRIBUTE_TYPE.MAX_HP] = 10
	attributes[UnitType.UNIT_ATTRIBUTE_TYPE.INITIAL_MORALE] = 5
	attributes[UnitType.UNIT_ATTRIBUTE_TYPE.MOVEMENT_SPEED] = 2
	attributes[UnitType.UNIT_ATTRIBUTE_TYPE.VISION_RANGE] = vision_range
	unit_type.attributes = attributes
	
	#Add the unit to the game state
	return game_state.addUnit(unit_type, pos, player)

#Test that own units always appear visible
func test_own_units_always_visible():
	var client_id: int = client_attributes.client_player_id
	#Add a few units 
	add_unit(client_id, Vector2i(0, 0))
	add_unit(client_id, Vector2i(1, 0))
	add_unit(client_id, Vector2i(1, 1))
	
	var visible: Variant = game_manager.get_visible_units()
	
	for unit in game_state.getUnits():
		if unit.get_player_id() == client_id:
			assert_true(unit in visible, "Own unit should be in visible units")

#Test that teammates units are always visible
func test_teammate_units_visible():
	var client_team_id: int = game_def.players.get(client_attributes.client_player_id).team.team_id
	#Add a few units 
	add_unit(player_2_id, Vector2i(0, 0))
	add_unit(player_2_id, Vector2i(1, 0))
	add_unit(player_2_id, Vector2i(1, 1))
	
	var visible: Variant = game_manager.get_visible_units()
	
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
			var visible: Variant = game_manager.get_visible_units()
			var dx: int = abs(unit_pos.x - enemy_pos.x)
			var dy: int = abs(unit_pos.y - enemy_pos.y)
			#Checks if enemy is within vision range
			if max(dx, dy) <= vision:
				assert_true(enemy_unit in visible, "Enemy at %s should be visible" % str(enemy_pos))
				assert_true(game_manager.is_tile_visible(enemy_pos), "Tile at %s should be visible" % str(enemy_pos))
			else:
				assert_false(enemy_unit in visible, "Enemy at %s should not be visible" % str(enemy_pos))
				assert_false(game_manager.is_tile_visible(enemy_pos), "Tile at %s should not be visible" % str(enemy_pos))

func test_cats_and_dogs_fog_of_war_vs_vision():
	var cats_dogs_res := load("res://game_cats_dogs.tres") as GameDefinitionResource
	var cats_dogs_mgr := GameDataManager.initFromGameDefinition(cats_dogs_res)
	# Client infantry at (17, 2) with vision_range = 2 should see nearby cat at (17, 0) but not middle dog at (10, 10)
	assert_true(cats_dogs_mgr.is_tile_visible(Vector2i(17, 0)), "Nearby cat tile (17, 0) should be visible in game_cats_dogs.tres")
	assert_false(cats_dogs_mgr.is_tile_visible(Vector2i(10, 10)), "Middle dog tile (10, 10) should be hidden in fog of war in game_cats_dogs.tres")

	var vision_res := load("res://game_cats_dogs_with_vision.tres") as GameDefinitionResource
	var vision_mgr := GameDataManager.initFromGameDefinition(vision_res)
	# In game_cats_dogs_with_vision.tres, client infantry have vision_range = 10 covering the entire 25x25 map
	for x in range(vision_mgr.get_grid().getWidth()):
		for y in range(vision_mgr.get_grid().getHeight()):
			assert_true(vision_mgr.is_tile_visible(Vector2i(x, y)), "Tile (%d, %d) should be visible in game_cats_dogs_with_vision.tres" % [x, y])

func test_grid_graphics_fog_of_war_overlay():
	var prev_popup_mgr := Global.popup_manager
	var gm_scene := preload("res://executioner/main/game_master/GameMaster.tscn")
	var gm: GameMaster = gm_scene.instantiate()
	add_child(gm)
	gm.grid_graphics.tile_grid.tile_set = gm.grid_graphics.tile_grid.tile_set.duplicate(true)

	var cats_dogs_res := load("res://game_cats_dogs.tres") as GameDefinitionResource
	gm.local_init_game(cats_dogs_res)
	assert_false(gm.grid_graphics.is_tile_fogged(Vector2i(17, 0)), "Visible tile (17, 0) should not be fogged in GridGraphics")
	assert_true(gm.grid_graphics.is_tile_fogged(Vector2i(10, 10)), "Unseen tile (10, 10) should be fogged in GridGraphics")

	var vision_res := load("res://game_cats_dogs_with_vision.tres") as GameDefinitionResource
	gm.local_init_game(vision_res)
	assert_false(gm.grid_graphics.is_tile_fogged(Vector2i(10, 10)), "Tile (10, 10) should not be fogged in game_cats_dogs_with_vision.tres")
	gm.free()
	Global.popup_manager = prev_popup_mgr



				
