class_name GameTeam



var _name: String
var _color: Color
var _id: int
var _units: Array


func _init(name: String, color: Color, id: int, units: Array) -> void: 
	_name = name
	_color = color
	_id = id
	_units = units



func get_name() -> String: 
	return _name

func get_color() -> Color: 
	return _color

func get_id() -> int:
	return _id
func get_units() -> Array: 
	return _units
