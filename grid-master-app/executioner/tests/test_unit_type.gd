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
