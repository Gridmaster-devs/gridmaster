class_name UnitType

# custom is futureproofing for custom movement types in the future
enum MOVEMENT_TYPE{WALKING = 0, TIRES = 1, TRACKS = 2, HOVERING = 3, TELEPORTING = 4, WATER = 5, CUSTOM = -1}
enum CAPTURABLE_TYPE{NO = 0, YES = 1}

var max_hp : int
var attack : int
var speed : int
var capturable : CAPTURABLE_TYPE
var movement_type : MOVEMENT_TYPE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
