class_name UnitResource
extends Resource
## Resource that describes a unit as defined by the unit editor

# holds string : Attribute pairs
@export var attributes : Dictionary

## @experimental these aren't anything right now
@export var actions : Array[Action]

var id: int:
	get:
		return get_attribute_value("id")
	set(v): return
static var _next_id: int = 0

var name: String:
	get:
		var name_attribute = get_attribute_value("name")
		if name_attribute == null:
			return ""
		else:
			return name_attribute
	set(v): return
	
func _init():
	set_attribute("id", _next_id)
	_next_id += 1

## takes an attribute of a certain name and puts its value in the dictionary
func set_attribute(name_p : String, value_p):
	#TODO: Probably need to check for null values
	if (name_p != null and value_p != null):
		var attribute = Attribute.create(name_p, value_p)
		attributes[name_p] = attribute


## checks whether and attribute exists in the dictionary and returns it if it does
func get_attribute(name_p : String):
	var attribute : Attribute = attributes.get(name_p)
	if (attribute != null):
		return attribute
	else:
		return null


## returns the value of the given attribute
func get_attribute_value(name_p : String):
	var attribute : Attribute = attributes.get(name_p)
	if (attribute == null): return null
	if (attribute.get_attribute_value() == null): return null
	return attribute.get_attribute_value()


## takes a an array of actions and saves it in the resource
func save_actions(action_array : Array[Action]):
	actions = action_array


## returns the actions saved in the resource
func load_actions():
	return actions
	

## Returns attribute dictionary
func getAttributes() -> Dictionary:
	return attributes

	
# debugging
func print_all():
	for i in attributes.values():
		i.print_all()
