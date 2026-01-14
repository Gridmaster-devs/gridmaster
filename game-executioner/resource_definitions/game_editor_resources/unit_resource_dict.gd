class_name UnitResourceDict
extends Resource

# holds string : Attribute pairs
@export var attributes : Dictionary
@export var actions : Array[Action]

# takes an attribute of a certain name and puts its value in the dictionary
func set_attribute(name_p : String, value_p):
	#TODO: Probably need to check for null values
	if (name_p != null and value_p != null):
		var attribute = Attribute.create(name_p, value_p)
		attributes[name_p] = attribute

# checks whether and attribute exists in the dictionary and returns it if it does
func get_attribute(name_p : String):
	var attribute : Attribute = attributes.get(name_p)
	if (attribute != null):
		return attribute
	else:
		return null

func get_attribute_value(name_p : String):
	var attribute : Attribute = attributes.get(name_p)
	if (attribute == null): return null
	if (attribute.get_attribute_value() == null): return null
	return attribute.get_attribute_value()

# takes a an array of actions and saves it in the resource
func save_actions(action_array : Array[Action]):
	actions = action_array


func load_actions():
	return actions
	
# debugging
func print_all():
	for i in attributes.values():
		i.print_all()
