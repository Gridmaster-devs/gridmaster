class_name UnitType
## Class that represents a type of unit and its attributes

## What type of movement the unit has
## Custom is futureproofing for custom movement types in the future
enum MOVEMENT_TYPE{WALKING = 0, TIRES = 1, TRACKS = 2, HOVERING = 3, TELEPORTING = 4, WATER = 5, CUSTOM = -1}

## Whether the unit is capturable or not
## Possible to add options in the future (ex. capturable at some % morale/hp)
enum CAPTURABLE_TYPE{NO = 0, YES = 1}

## Enum containing all attribute types
enum ATTRIBUTE_TYPE{ATTACK,
					ARMOR_PIERCING,
					ACCURACY,
					ATTACK_RANGE,
					MAX_HP,
					CAPTURABLE,
					ARMOR,
					DODGE,
					SPEED,
					MOVEMENT_T,
					VISION_RANGE,
					PERCEPTION,
					VICTORY_POINTS,
					INITIAL_MORALE
}


# info
# assigned by the gamestate object on creation
var type_id : int
var name : String
var description : String

## Dictionary containing the value of each attribute
var attributes : Dictionary[ATTRIBUTE_TYPE, Variant]

## Dictionary containing the flat modifiers to attributes, like +1 speed
var flat_modifiers : Dictionary[ATTRIBUTE_TYPE, float]

## Dictionary containing the percentage modifiers to attributes, like +20% attack
var percentage_modifiers : Dictionary[ATTRIBUTE_TYPE, float]


# TODO
func initFromUnitResource():
	pass


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
