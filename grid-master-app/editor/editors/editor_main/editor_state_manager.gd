class_name EditorStateManager
extends RefCounted

var state: EditorState

func get_selected_unit() -> UnitResource:
	return state.get_selected_unit()

func set_selected_unit(id: int) -> void:
	state.set_selected_unit(id)

func get_units() -> Array[UnitResource]:
	return state.get_units()
	 
func clear_units() -> void:
	state.clear_units()
	
func add_unit(unit: UnitResource) -> void:
	state.add_unit(unit)
