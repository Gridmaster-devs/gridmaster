extends Node


@onready var tile_map = get_node("/root/MapEditor/VBoxContainer/HBoxContainer/SubViewControl/SubViewportContainer/SubViewport/TileMapLayer")
@onready var tile_lib = get_node("/root/MapEditor/VBoxContainer/HBoxContainer/EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Tile library/GridContainer")
@onready var color_picker = $"../ColorPicker"
@onready var parent_ref = $"../../../../../../.."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.pressed.connect(_on_button_pressed)

	
func _on_button_pressed():
	var vbox := VBoxContainer.new()
	var new_button := Button.new()
	new_button.icon = parent_ref.cur_texture
	new_button.custom_minimum_size = Vector2(84, 84)
	var tile_button_script := load("res://scripts/map-editor-scripts/side_panel_scripts/tile_button_script.gd")
	new_button.set_script(tile_button_script)
	new_button.source = parent_ref.cur_source

	
	var label := Label.new()
	label.text = "Tile Name"
	label.custom_minimum_size = Vector2(84, 84)
	vbox.add_child(new_button)
	vbox.add_child(label)
	
	parent_ref.tile_lib.add_child(vbox)
	parent_ref.queue_free()
