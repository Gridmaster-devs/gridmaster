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

func set_units(new_units: Array) -> void:
	_units = new_units

func add_unit(unit_name: String) -> void: 
	if _units.has(unit_name):
		return
	_units.append(unit_name)
	
func remove_unit(unit_name: String) -> void: 
	_units.erase(unit_name)

func set_name(new_name: String) -> void:
	_name = new_name

func set_color(new_color: Color) -> void:
	_color = new_color

func get_name() -> String: 
	return _name

func get_color() -> Color: 
	return _color

func get_id() -> int:
	return _id
func get_units() -> Array: 
	return _units
