extends Node

@onready var parent_ref = $"../../../../../../.."

#tile info
@onready var name_ui = $"../../../General/Name/HBoxContainer/LineEdit"
@onready var protection_ui = $"../../../Stats/Protection/HBoxContainer/LineEdit"
@onready var movement_ui = $"../../../Stats/Movement/HBoxContainer/LineEdit"
@onready var hiding_ui = $"../../../Stats/Hiding/HBoxContainer/LineEdit"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.pressed.connect(_on_button_pressed)

	
func _on_button_pressed():
	parent_ref.addNewTile(name_ui.text, protection_ui.text.to_int(), hiding_ui.text.to_int(), movement_ui.text.to_int())
	
	
	
	
	
	
	
	
	
	
	
	
	
	
