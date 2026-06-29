class_name UnitType
extends RefCounted
## Class that represents a type of unit and its attributes

## What type of movement the unit has
## Custom is futureproofing for custom movement types in the future
enum UNIT_MOVEMENT_TYPE{WALKING = 0, TIRES = 1, TRACKS = 2, HOVERING = 3, TELEPORTING = 4, WATER = 5, FLYING = 6, CUSTOM = -1}

## Whether the unit is capturable or not
## Possible to add options in the future (ex. capturable at some % morale/hp)
enum CAPTURABLE_TYPE{NO = 0, YES = 1}

## Enum containing all attribute types
enum UNIT_ATTRIBUTE_TYPE{ATTACK,
					ARMOR_PIERCING,
					ACCURACY,
					ATTACK_RANGE,
					MAX_HP,
					CAPTURABLE,
					ARMOR,
					DODGE,
					MOVEMENT_SPEED,
					MOVEMENT_TYPE,
					VISION_RANGE,
					PERCEPTION,
					VICTORY_POINTS,
					INITIAL_MORALE
}

## Dictionary for converting the attributes given by the unit editor into
## ones understood by the game executioner
const attribute_conversion_table : Dictionary[String, UNIT_ATTRIBUTE_TYPE] = {
	"attack" : UNIT_ATTRIBUTE_TYPE.ATTACK,
	"armor_piercing" : UNIT_ATTRIBUTE_TYPE.ARMOR_PIERCING,
	"accuracy" : UNIT_ATTRIBUTE_TYPE.ACCURACY,
	"attack_range" : UNIT_ATTRIBUTE_TYPE.ATTACK_RANGE,
	"health" : UNIT_ATTRIBUTE_TYPE.MAX_HP,
	"capturable" : UNIT_ATTRIBUTE_TYPE.CAPTURABLE,
	"armor" : UNIT_ATTRIBUTE_TYPE.ARMOR,
	"evasion" : UNIT_ATTRIBUTE_TYPE.DODGE,
	"movement_speed" : UNIT_ATTRIBUTE_TYPE.MOVEMENT_SPEED,
	"movement_type" : UNIT_ATTRIBUTE_TYPE.MOVEMENT_TYPE,
	"vision_range" : UNIT_ATTRIBUTE_TYPE.VISION_RANGE,
	"perception" : UNIT_ATTRIBUTE_TYPE.PERCEPTION,
	"victory_points" : UNIT_ATTRIBUTE_TYPE.VICTORY_POINTS,
	"morale" : UNIT_ATTRIBUTE_TYPE.INITIAL_MORALE
}


# info
# assigned by the gamestate object on creation
var type_id : int ## ID of the unit type
var unit_name : String ## Name of the unit type
var description : String ## Description of the unit type
var texture : Texture2D ## Texture used to draw the unit

# These are used for production units and units that can be produced
var is_production_unit: bool = false
var producible_units: Array[UnitType] = []
var producible_units_ids: Array = []
var is_producible_unit: bool = false
var production_cost: int = 1



## Dictionary containing the value of each attribute
var attributes : Dictionary[UNIT_ATTRIBUTE_TYPE, Variant]


## Dictionary containing the flat modifiers to attributes, like +1 speed
var flat_modifiers : Dictionary[UNIT_ATTRIBUTE_TYPE, float]


## Dictionary containing the percentage modifiers to attributes, like +20% attack
var percentage_modifiers : Dictionary[UNIT_ATTRIBUTE_TYPE, float]


## Makes sure all attributes are present after loading from resource
func checkAttributes() -> void:
	for type in UNIT_ATTRIBUTE_TYPE.values():
		assert(attributes.get(type) != null, "Attribute %s missing after loading from resource!" % UNIT_ATTRIBUTE_TYPE.keys()[type])


# TODO: This isn't checking the values from the unit resource too closely.
# Problems may occur with attributes like capturable
# Might be a good idea to check that each attribute's value is of the correct type and makes sense
## Initializes a unit type from a unit resource
static func initFromUnitResource(unit_resource : UnitResource) -> UnitType:

	# TODO: Tidy up whatever mess of importing attributes this method is.

	var unit_type = UnitType.new()
	unit_type.type_id = unit_resource.get_attribute_value("id")
	var resource_attributes = unit_resource.getAttributes()
	unit_type.unit_name = unit_resource.get_attribute_value("name")
	unit_type.description = unit_resource.get_attribute_value("description")
	unit_type.texture = unit_resource.get_attribute_value("texture")

	unit_type.is_production_unit = unit_resource.get_attribute_value("is_production_unit")
	unit_type.is_producible_unit = unit_resource.get_attribute_value("is_producible_unit")
	unit_type.production_cost = unit_resource.get_attribute_value("production_cost")
	var producible_units_from_resource = unit_resource.get_attribute_value("producible_units")
	if producible_units_from_resource != null and producible_units_from_resource != []:
		unit_type.producible_units_ids = producible_units_from_resource
	
	for key in resource_attributes.keys():
		if (key == "name" or key == "description" or key == "texture" or key == "is_production_unit" 
			or key == "is_producible_unit" or key == "production_cost" or key == "producible_units" or key == "id"):
			continue

		var value = unit_resource.get_attribute_value(key)
		
		assert(value != null, "Attribute %s value in unit resource should not be null!" % key)
		
		var attribute_type : UNIT_ATTRIBUTE_TYPE = attribute_conversion_table.get(key)
		if (attribute_type != null):
			unit_type.attributes.set(attribute_type, value)
			
		
	unit_type.checkAttributes()
	
	return unit_type

func populate_producible_units(unit_types_dict: Dictionary[int, UnitType]) -> void:
	for unit_id in producible_units_ids:
		if unit_types_dict.has(unit_id):
			producible_units.append(unit_types_dict[unit_id])
		else:
			print("UnitType with ID %d not found in unit_types_dict!" % unit_id)

static func debugType() -> UnitType:
	var type = UnitType.new()
	type.debugInit()
	return type


func debugInit() -> void:
	type_id = -1
	unit_name = "Test unit"
	description = "Unit for testing"
	for a : int in UNIT_ATTRIBUTE_TYPE.values():
		attributes.set(a, 1)
	

## Returns a string with info about the unit type
func _to_string() -> String:
	return "(Unit type name: %s, Unit type ID: %s)" % [unit_name, str(type_id)]


## Constructor
func _init() -> void:
	pass
