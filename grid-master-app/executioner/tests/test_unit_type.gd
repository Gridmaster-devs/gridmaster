extends GutTest

var unit_resource: UnitResource

# Initialize unit resource and set its attributes
func before_each():
	unit_resource = UnitResource.new()
	unit_resource.set_attribute("name", "Test Unit")
	unit_resource.set_attribute("description", "Testing unit")

	unit_resource.set_attribute("is_production_unit", true)
	unit_resource.set_attribute("is_producible_unit", true)
	unit_resource.set_attribute("production_cost", 100)
	unit_resource.set_attribute("producible_units", [1])
	
	
	for a : String in UnitType.attribute_conversion_table.keys():
		unit_resource.set_attribute(a, 1)

# Clear the unit resource
func after_each():
	unit_resource = null

# Test initializing UnitType from a UnitResourceDict


func test_init_from_unit_resource():
	var unit_type: UnitType = UnitType.initFromUnitResource(unit_resource)
	
	for a : String in unit_type.attribute_conversion_table.keys():
		var attribute_type: UnitType.UNIT_ATTRIBUTE_TYPE = unit_type.attribute_conversion_table.get(a)
		var attribute_value: Variant = unit_type.attributes.get(attribute_type)
		assert_eq(unit_resource.get_attribute(a).get_attribute_value(), attribute_value)


func test_decimal_combat_attributes_from_unit_resource() -> void:
	unit_resource.set_attribute("accuracy", 75.3)
	unit_resource.set_attribute("evasion", 42.7)
	var unit_type: UnitType = UnitType.initFromUnitResource(unit_resource)
	var unit := Unit.new(unit_type, 1, Player.DEBUG_new_player(), Vector2i.ZERO)

	assert_almost_eq(unit.accuracy, 75.3, 0.0001)
	assert_almost_eq(unit.dodge, 42.7, 0.0001)


func test_zero_production_cost_loads_as_one() -> void:
	unit_resource.set_attribute("production_cost", 0)
	var unit_type: UnitType = UnitType.initFromUnitResource(unit_resource)
	assert_eq(unit_type.production_cost, 1)


func test_positive_production_cost_is_preserved() -> void:
	var unit_type: UnitType = UnitType.initFromUnitResource(unit_resource)
	assert_eq(unit_type.production_cost, 100)

# Test legacy unit resource without 'id' or production attributes


func test_init_from_legacy_unit_resource() -> void:
	var legacy_res = UnitResource.new()
	legacy_res.attributes.erase("id")
	legacy_res.set_attribute("name", "Legacy Cat")
	legacy_res.set_attribute("description", "A legacy unit")
	for a : String in UnitType.attribute_conversion_table.keys():
		legacy_res.set_attribute(a, 1)

	var unit_type: UnitType = UnitType.initFromUnitResource(legacy_res, 99)
	assert_eq(unit_type.type_id, 99)
	assert_eq(unit_type.unit_name, "Legacy Cat")
	assert_false(unit_type.is_production_unit)
	assert_false(unit_type.is_producible_unit)
	assert_eq(unit_type.production_cost, 1)


func test_producible_units_only_resolve_enabled_targets() -> void:
	var producer: UnitType = UnitType.initFromUnitResource(unit_resource)
	var enabled: UnitType = UnitType.initFromUnitResource(unit_resource)
	unit_resource.set_attribute("is_producible_unit", false)
	var disabled: UnitType = UnitType.initFromUnitResource(unit_resource)
	unit_resource.attributes.erase("is_producible_unit")
	var legacy: UnitType = UnitType.initFromUnitResource(unit_resource)
	producer.producible_units_ids = [1, 2, 3, 99]
	producer.populate_producible_units({1: enabled, 2: disabled, 3: legacy})
	assert_eq(producer.producible_units, [enabled])

# Test loading cats and dogs game definition resources


func test_load_cats_and_dogs_game():
	var game_res = load("res://game_cats_dogs.tres") as GameDefinitionResource
	assert_not_null(game_res, "game_cats_dogs.tres should be loadable")
	var data_mgr = GameDataManager.initFromGameDefinition(game_res)
	assert_not_null(data_mgr, "GameDataManager should initialize successfully from game_cats_dogs.tres")
	assert_eq(data_mgr.get_game_name(), "Cats and Dogs")


func test_load_cats_and_dogs_with_vision_game():
	var game_res = load("res://game_cats_dogs_with_vision.tres") as GameDefinitionResource
	assert_not_null(game_res, "game_cats_dogs_with_vision.tres should be loadable")
	var data_mgr = GameDataManager.initFromGameDefinition(game_res)
	assert_not_null(data_mgr, "GameDataManager should initialize successfully from game_cats_dogs_with_vision.tres")
	assert_eq(data_mgr.get_game_name(), "Cats and Dogs (Vision)")

