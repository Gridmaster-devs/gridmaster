extends GutTest

var game_def: GameDefinition


func before_each():
	game_def = GameDefinition.new()


#Helper function to create a unit resource with the given name and ID
func create_unit_resource(unit_name: String, id: int) -> UnitResource:
	var unit_resource: UnitResource = UnitResource.new()
	unit_resource.set_attribute("id", id)
	unit_resource.set_attribute("name", unit_name)
	unit_resource.set_attribute("description", "")
	unit_resource.set_attribute("is_production_unit", false)
	unit_resource.set_attribute("is_producible_unit", false)
	unit_resource.set_attribute("production_cost", 1)
	for a : String in UnitType.attribute_conversion_table.keys():
		unit_resource.set_attribute(a, 1)
	return unit_resource

#Test that unit types with the same ID don't overwrite each other
func test_duplicate_unit_type_ids_are_kept_apart():
	var game_resource: GameDefinitionResource = GameDefinitionResource.new()
	game_resource.save_units([
		create_unit_resource("Black Pawn", 0),
		create_unit_resource("Black King", 1),
		create_unit_resource("White Pawn", 0),
		create_unit_resource("White King", 1)
	] as Array[UnitResource])

	var unit_name_type_dict: Dictionary[String, int] = {}
	game_def.initUnitTypesFromResource(game_resource, unit_name_type_dict)

	assert_eq(game_def.unit_types.size(), 4)
	for unit_name in ["Black Pawn", "Black King", "White Pawn", "White King"]:
		var type_id: int = unit_name_type_dict[unit_name]
		assert_eq(game_def.unit_types[type_id].unit_name, unit_name)
