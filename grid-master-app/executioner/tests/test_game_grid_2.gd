extends GutTest

var game_grid : GameGrid
var width = 10
var height = 10

func before_each():
	game_grid = GameGrid.new(width, height)

func test_initialization():
	assert_eq(game_grid.getWidth(), width, "Width should be initialized correctly")
	assert_eq(game_grid.getHeight(), height, "Height should be initialized correctly")
	assert_not_null(game_grid.tiles, "Tiles array should be initialized")

func test_filling_init():
	var fill_func = func(_x, _y):
			return GridTile.new(TileType.new())
	game_grid.fillTiles(fill_func)
	
	for i in range(width):
		for j in range(height):
			assert_not_null(game_grid.getTile(i, j), "Tile shouldn't be null")

func test_tile_access_and_modification():
	var x = 5
	var y = 5
	
	# Create a new tile type for testing.
	var tile_type = TileType.new()
	tile_type.type_id = 1
	tile_type.tile_name = "TestTile"
	
	var fill_func = func(_x, _y):
		return GridTile.new(TileType.new())
	game_grid.fillTiles(fill_func)
	
	# Assign the test tile type to the 
	game_grid.setTileType(x, y, tile_type)
	assert_eq(game_grid.getTileType(x, y), tile_type, "Tile type should be updated")
	assert_eq(game_grid.getTile(x, y).getTileType().tile_name, "TestTile", "Tile name should match")

func test_unit_management():
	# Setup grid with tiles
	var fill_func = func(_x, _y):
		return GridTile.new(TileType.new())
	game_grid.fillTiles(fill_func)
	
	# Create dependencies for Unit
	var unit_type = UnitType.new()
	var attributes: Dictionary[UnitType.UNIT_ATTRIBUTE_TYPE, Variant] = {}
	attributes[UnitType.UNIT_ATTRIBUTE_TYPE.MAX_HP] = 10
	attributes[UnitType.UNIT_ATTRIBUTE_TYPE.INITIAL_MORALE] = 5
	attributes[UnitType.UNIT_ATTRIBUTE_TYPE.MOVEMENT_SPEED] = 2
	unit_type.attributes = attributes
	
	var unit_pos = Vector2i(1, 1)
	var unit = Unit.new(unit_type, 1, 1, unit_pos)
	
	game_grid.addUnit(unit)
	
	var units_on_tile = game_grid.getUnitsOnTile(1, 1)
	assert_true(units_on_tile.size() > 0, "Should have units on tile")
	# Assuming getUnitsOnTile returns Dictionary[int, Unit] per GameGrid.gd signature
	assert_has(units_on_tile, unit.getId(), "Recently added unit should be in the returned units")

#func test_init_from_map_resource():
	## Create a mock map
	#var map = GameMap.new()
	#var grid_resource = Grid.new()
	#grid_resource.width = 2
	#grid_resource.height = 2
	## 0 will be referring to the strategic tile type
	## named "Grass" defined below as part of the 
	## strategic tile information.
	#grid_resource.grid = [0, 0, 0, 0]
	#map.grid = grid_resource
	#
	#var strat_tile = StrategicTileInformation.new()
	#strat_tile.source = 0
	#strat_tile.name = "Grass"
	#strat_tile.movement = 1
	#strat_tile.hiding = 2
	#strat_tile.protection = 3
	#
	#var strat_tile_map: Dictionary[int, StrategicTileInformation] = {}
	#strat_tile_map[0] = strat_tile
	#map.strategic_tile_information_map = strat_tile_map
	#
	#var created_grid = GameGrid.initFromMapResource(map)
	#
	#assert_eq(created_grid.width, 2, "Width should match map")
	#assert_eq(created_grid.height, 2, "Height should match map")
	#
	## Check that all the tiles are grass tiles and their attribute type is movement
	#for i in range(2):
		#for j in range(2):
			#var t = created_grid.getTileType(i, j)
			#assert_not_null(t, "Tile type should be populated")
			#assert_eq(t.tile_name, "Grass", "Tile name should match resource")
			#assert_eq(t.attributes.get(TileType.TILE_ATTRIBUTE_TYPE.MOVEMENT), 1, "Movement attribute should match")
