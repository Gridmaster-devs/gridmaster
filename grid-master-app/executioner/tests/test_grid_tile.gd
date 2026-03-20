extends GutTest

var grid_tile: GridTile
var unit: Unit

# Create a GridTile before each test is run
func before_each():
	var team: Team = Team.new("Test team", -1, Color(0, 0, 0), [])
	var player: Player = Player.new("Test player", -1, team, false)
	unit = Unit.new(UnitType.debugType(), -1, player, Vector2i(1,1))
	grid_tile = GridTile.new(TileType.debugTile(), Vector2i(1,1))
	
# Clear the GridTile after each test
func after_each():
	grid_tile = null
	
# Test adding a unit 
func test_adding_units():
	
	# Add unit to the tile
	grid_tile.addUnit(unit)
	
	# Check that unit was added to the tile
	var added_unit: Unit = grid_tile.get_unit()
	assert_not_null(added_unit, "The grid should contain the added unit")
	# Check that the added unit was the correct one
	assert_eq(added_unit, unit, "The fetched unit should match the unit that was added")
	
	
# Test adding multiple units
func test_adding_multiple_units():
	var team: Team = Team.new("Test team", -1, Color(0, 0, 0), [])
	var player: Player = Player.new("Test player", -1, team, false)
	var unit2: Unit = Unit.new(UnitType.debugType(), 1, player, Vector2i(1,1))
	
	# Add units
	grid_tile.addUnit(unit)
	grid_tile.addUnit(unit2)
	
	# Check that the added unit is the one added second
	assert_eq(grid_tile.get_unit(), unit2, "The tile should contain unit2")

# Test getting a unit that wasn't added to the tile
func test_getting_not_added_unit():
	assert_null(grid_tile.get_unit(), "The tile should not contain a unit that wasn't added")

# Test removing a unit
func test_unit_removal():
	# Add unit to the tile
	grid_tile.addUnit(unit)
	
	# Remove unit
	grid_tile.remove_unit()
	# Check that the unit was removed 
	assert_null(grid_tile.get_unit(), "The added unit should have been removed")
	
