extends Node

@onready var color_picker = $"../ColorPicker"
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
	var vbox := VBoxContainer.new()
	var new_button := Button.new()
	new_button.icon = parent_ref.cur_texture
	new_button.expand_icon = true
	new_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	new_button.custom_minimum_size = Vector2(84, 84)
	var tile_button_script := load("res://scripts/map_editor_scripts/button_scripts/tile_button_script.gd")
	new_button.set_script(tile_button_script)
	new_button.source = parent_ref.cur_source
	new_button.parent_ref = parent_ref.parent_ref

	
	var label := Label.new()
	label.text = name_ui.text
	label.custom_minimum_size = Vector2(84, 84)
	vbox.add_child(new_button)
	vbox.add_child(label)
	
	if parent_ref.parent_ref.cur_gw == parent_ref.parent_ref.GridView.STRATEGIC: 
		parent_ref.parent_ref.tile_strategic_map[parent_ref.cur_source] = \
			StrategicTileInformation.new(parent_ref.cur_source, name_ui.text, 
			protection_ui.text.to_int(), movement_ui.text.to_int(), 
			hiding_ui.text.to_int(), parent_ref.cur_texture)
	else: 
		parent_ref.parent_ref.tile_tactical_map[parent_ref.cur_source] = \
			TacticalTileInformation.new(parent_ref.cur_source, name_ui.text, 
			protection_ui.text.to_int(), movement_ui.text.to_int(), 
			hiding_ui.text.to_int(), parent_ref.cur_texture)
	
	
	parent_ref.parent_ref.add_new_tile_to_library(vbox)
	parent_ref.queue_free()
