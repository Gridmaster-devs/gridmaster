extends GutTest

# Test initializing a unit
func test_unit_init():
	var unit_type: UnitType = UnitType.debugType()
	var unit: Unit = Unit.new(unit_type, -1, -1, Vector2i(1, 1))

	unit.initFromUnitType()
	
	assert_eq(unit.hp, 1, "Unit hp should be set to 1")
	assert_eq(unit.morale, 1, "Unit morale sould be set to 1")
