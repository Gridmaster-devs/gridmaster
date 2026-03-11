extends Resource
class_name MapPainterRes


@export var _attribute_grids: Array[Array2D]
@export var _lib_items_data: Dictionary[String, Array]
@export var _width: int
@export var _height: int

func init(width: int, height:int, attribute_grids: Array[Array2D], lib_items_data: Dictionary[String, Array]) -> void: 
	_attribute_grids = attribute_grids
	_lib_items_data = lib_items_data
	_width = width
	_height = height

func get_attribute_grids() -> Array[Array2D]:
	return _attribute_grids

func get_lib_items() -> Dictionary[String, Array]:
	return _lib_items_data


func get_width() -> int:
	return _width
func get_height() -> int:
	return _height
