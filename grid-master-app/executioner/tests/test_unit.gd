extends GutTest

# Test initializing a unit
func test_unit_init():
	var unit_type: UnitType = UnitType.debugType()
	var team: Team = Team.new("Test team", -1, Color(0, 0, 0), [])
	var player: Player = Player.new("Test player", -1, team, false)
	var unit: Unit = Unit.new(unit_type, -1, player, Vector2i(1, 1))

	unit.initFromUnitType()
	
	assert_eq(unit.hp, 1, "Unit hp should be set to 1")
	assert_eq(unit.morale, 1, "Unit morale sould be set to 1")
	assert_false(unit.is_dead(), "Unit should not be dead upon initialization")

# Test taking damage and death state
func test_unit_damage_and_death():
	var unit_type: UnitType = UnitType.debugType()
	var player: Player = Player.DEBUG_new_player()
	var unit: Unit = Unit.new(unit_type, 1, player, Vector2i(2, 2))

	assert_false(unit.is_dead(), "Unit should be alive initially")
	unit.take_damage(1)
	assert_eq(unit.hp, 0, "Unit hp should be 0 after taking 1 damage")
	assert_true(unit.is_dead(), "Unit should be reported as dead when HP is 0 or less")

# Test position update
func test_unit_set_position():
	var unit_type: UnitType = UnitType.debugType()
	var player: Player = Player.DEBUG_new_player()
	var unit: Unit = Unit.new(unit_type, 1, player, Vector2i(0, 0))

	assert_eq(unit.getPosition(), Vector2i(0, 0))
	unit.set_position(Vector2i(5, 7))
	assert_eq(unit.getPosition(), Vector2i(5, 7), "Unit position should update correctly")

