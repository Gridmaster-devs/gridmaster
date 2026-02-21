extends GutTest

var grid_tile: GridTile

# Create a GridTile before each test is run
func before_each():
	grid_tile = GridTile.new(TileType.debugTile())
	
# Clear the GridTile after each test
func after_each():
	grid_tile = null
	
# Test adding a unit 
func test_adding_units():
	
	# Add unit to the tile
	var unit: Unit = Unit.new(UnitType.debugType(), -1, -1, Vector2i(1,1))
	var initial_size: int = grid_tile.getUnits().size()
	grid_tile.addUnit(unit)
	
	# Check that unit was added to the tile
	var added_unit: Unit = grid_tile.getUnitById(unit.getId())
	assert_not_null(added_unit, "The grid should contain the added unit")
	# Check that the added unit was the correct one
	assert_eq(added_unit, unit, "The fetched unit should match the unit that was added")
	# Check that the size of the units dictionary was incremented
	assert_eq(initial_size + 1, grid_tile.getUnits().size(), "The size of units should be incremented")

# Test adding multiple units
func test_adding_multiple_units():
	var unit1: Unit = Unit.new(UnitType.debugType(), -1, -1, Vector2i(1,1))
	var unit2: Unit = Unit.new(UnitType.debugType(), 1, -1, Vector2i(1,1))
	
	# Add units
	grid_tile.addUnit(unit1)
	grid_tile.addUnit(unit2)
	
	var correct_units: Dictionary[int, Unit] = {
		unit1.getId(): unit1,
		unit2.getId(): unit2,
	}
	# Check that both units were added
	assert_eq(grid_tile.getUnits(), correct_units, "The tile should contain both units")

# Test getting a unit that wasn't added to the tile
func test_getting_not_added_unit():
	var unit: Unit = Unit.new(UnitType.debugType(), -1, -1, Vector2i(1,1))
	assert_null(grid_tile.getUnitById(unit.getId()), "The tile should not contain a unit that wasn't added")

# Test removing a unit
func test_unit_removal():
	# Add unit to the tile
	var unit: Unit = Unit.new(UnitType.debugType(), -1, -1, Vector2i(1,1))
	var initial_size: int = grid_tile.getUnits().size()
	grid_tile.addUnit(unit)
	
	# Remove unit by id
	grid_tile.removeUnitById(unit.getId())
	# Check that the unit was removed 
	assert_null(grid_tile.getUnitById(unit.getId()), "The added unit should have been removed")
	# Check that the size of units is the same after adding and removing teh unit
	assert_eq(initial_size, grid_tile.getUnits().size(), "The number of units should be the same to what it was at the start")
