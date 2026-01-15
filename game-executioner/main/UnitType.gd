class_name UnitType
## Class that represents a type of unit and its attributes

## What type of movement the unit has
## Custom is futureproofing for custom movement types in the future
enum MOVEMENT_TYPE{WALKING = 0, TIRES = 1, TRACKS = 2, HOVERING = 3, TELEPORTING = 4, WATER = 5, CUSTOM = -1}

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
					SPEED,
					MOVEMENT_T,
					VISION_RANGE,
					PERCEPTION,
					VICTORY_POINTS,
					INITIAL_MORALE
}


# info
# assigned by the gamestate object on creation
var type_id : int ## ID of the unit type
var unit_name : String ## Name of the unit type
var description : String ## Description of the unit type
var texture : Texture2D ## Texture used to draw the unit

## Dictionary containing the value of each attribute
var attributes : Dictionary[UNIT_ATTRIBUTE_TYPE, Variant]

## Dictionary containing the flat modifiers to attributes, like +1 speed
var flat_modifiers : Dictionary[UNIT_ATTRIBUTE_TYPE, float]

## Dictionary containing the percentage modifiers to attributes, like +20% attack
var percentage_modifiers : Dictionary[UNIT_ATTRIBUTE_TYPE, float]


# TODO
func initFromUnitResource():
	pass
