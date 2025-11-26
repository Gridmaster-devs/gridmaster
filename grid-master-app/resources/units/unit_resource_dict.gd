class_name UnitResourceDict
extends Resource

# holds string : Attribute pairs
var attributes : Dictionary

func set_attribute(name_p : String, value_p):
	#TODO: Probably need to check for null values
	var attribute = Attribute.create(name_p, value_p)
	attributes[name_p] = attribute

func get_attribute(name_p : String):
	return attributes[name_p]
	
# debugging
func print_all():
	for i in attributes.values():
		i.print_all()
