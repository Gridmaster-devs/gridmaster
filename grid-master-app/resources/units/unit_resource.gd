class_name UnitResource
extends Resource

@export_category("Info")
@export var name : String
@export var description : String
@export var image : ImageTexture

@export_category("Attributes")
@export_group("Movement")
@export_enum(
	"Walking", 
	"Wheels", 
	"Tracks", 
	"Hovering", 
	"Flying", 
	"Floating", 
	"Teleporting") var movement_type : int
@export var capturable : bool
@export_group("Interaction")
@export_group("")

@export_category("Resources")
@export_group("Vitality")
@export var health : int
@export var morale : int
@export_group("")

@export_category("Stats")
@export_group("Offensive")
@export var damage : int
@export var piercing : int
@export var accuracy : int
@export var reach : int
@export_group("Defensive")
@export var armor : int
@export var evasion : int
@export_group("Utility")
@export var perception : int
@export var vision_range : int
@export_group("Value")
@export var victory_points : int
@export_group("")

@export_category("Actions")
@export_group("Orders")
@export_group("")
