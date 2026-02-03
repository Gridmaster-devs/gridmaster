class_name UnitResource
extends Resource
## Resource that describes a unit as defined by the unit editor

# holds string : Attribute pairs
@export var attributes : Dictionary
@export var actions : Array[Action]


## takes an attribute of a certain name and puts its value in the dictionary
func set_attribute(name_p : String, value_p: Variant) -> void:
	#TODO: Probably need to check for null values
	if (name_p != null and value_p != null):
		var attribute = Attribute.create(name_p, value_p)
		attributes[name_p] = attribute


## returns the attribute value or null if name_p isn't in the dictionary keys
func get_attribute(name_p : String) -> Variant:
	return attributes.get(name_p)


## returns the value of the given attribute
func get_attribute_value(name_p : String) -> Variant:
	var attribute : Attribute = attributes.get(name_p)
	if (attribute): return attribute.get_attribute_value()
	return null


## takes a an array of actions and saves it in the resource
func save_actions(action_array : Array[Action]) -> void:
	actions = action_array


## returns the actions saved in the resource
func load_actions() -> Array:
	return actions
	

## Returns attribute dictionary
func getAttributes() -> Dictionary:
	return attributes

	
# debugging
func print_all() -> void:
	for i in attributes.values():
		i.print_all()
