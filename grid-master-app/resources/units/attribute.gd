class_name Attribute
extends Resource

enum Type {STRING, INT, FLOAT}

@export var name : String
@export var type : Type
@export var value : Variant

# creates a new instance of Attribute
# _p here means parameter, distinguishing it from the other variables
static func create(name_p : String, value_p):
	var attribute = Attribute.new()
	attribute.name = name_p
	attribute.value = value_p
	
	if (value_p is int):
		attribute.type = Type.INT
	elif (value_p is String):
		attribute.type = Type.STRING
	elif (value_p is float):
		attribute.type = Type.FLOAT
	
	assert(attribute.type != null, "The value of the attribute must be an int, string, or float")
	return attribute



# debugging, prints all there is to the Attribute
func print_all():
	print("Attribute: " + str(name) + ", value: " + str(value) + "\n")
