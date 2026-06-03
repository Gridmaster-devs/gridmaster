class_name EditorState
extends RefCounted

var unit_resources: Array[UnitResource] = []

var selected_unit: UnitResource

func get_selected_unit() -> UnitResource:
	return selected_unit

func set_selected_unit(id: int):
	for unit in unit_resources:
		if unit.id == id:
			selected_unit = unit

func get_units()-> Array[UnitResource]:
	return unit_resources

func clear_units():
	unit_resources = []
	
func add_unit(unit: UnitResource):
	unit_resources.append(unit)
