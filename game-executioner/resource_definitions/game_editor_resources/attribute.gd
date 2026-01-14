class_name Attribute
extends Resource

# the type of the value in the attribute
# this isn't currently used anywhere because gdscript is good enough
# at dealing with different types of values, but I'd strongly
# recommend updating this if you add a new type of value
enum Type {STRING, INT, FLOAT}

@export var attribute_name : String
@export var type : Type
@export var attribute_value : Variant

# creates a new instance of Attribute
# _p here means parameter, distinguishing it from the other variables
static func create(name_p : String, value_p):
	var attribute = Attribute.new()
	attribute.attribute_name = name_p
	attribute.attribute_value = value_p
	
	if (value_p is int):
		attribute.type = Type.INT
	elif (value_p is String):
		attribute.type = Type.STRING
	elif (value_p is float):
		attribute.type = Type.FLOAT
	
	assert(attribute.type != null, "The value of the attribute must be an int, string, or float")
	return attribute

func get_attribute_name():
	return attribute_name
	
func get_attribute_value():
	return attribute_value

# debugging, prints all there is to the Attribute
func print_all():
	print("Attribute: " + str(attribute_name) + ", value: " + str(attribute_value) + "\n")
