extends Resource
class_name MapPainterRes


@export var _attribute_grid: Array2D
@export var _lib_items_data: Dictionary[String, Array]


func init(attribute_grid: Array2D, lib_items_data: Dictionary[String, Array]) -> void: 
	_attribute_grid = attribute_grid
	_lib_items_data = lib_items_data

func get_attribute_grid() -> Array2D:
	return _attribute_grid

func get_lib_items() -> Dictionary[String, Array]:
	return _lib_items_data
