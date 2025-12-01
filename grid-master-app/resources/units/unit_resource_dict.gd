class_name UnitResourceDict
extends Resource

# holds string : Attribute pairs
@export var attributes : Dictionary

func set_attribute(name_p : String, value_p):
	#TODO: Probably need to check for null values
	if (name_p != null and value_p != null):
		var attribute = Attribute.create(name_p, value_p)
		attributes[name_p] = attribute

func get_attribute(name_p : String):
	var attribute : Attribute = attributes.get(name_p)
	if (attribute != null):
		return attribute.value
	else:
		return null
	
# debugging
func print_all():
	for i in attributes.values():
		i.print_all()
