extends Node


@onready var tile_map = get_node("/root/MapEditor/VBoxContainer/HBoxContainer/SubViewControl/SubViewportContainer/SubViewport/TileMapLayer")
@onready var tile_lib = get_node("/root/MapEditor/VBoxContainer/HBoxContainer/EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Tile library/GridContainer")
@onready var color_picker = $"../ColorPicker"


var cur_source = 0
var cur_texture = Texture.new()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.pressed.connect(_on_button_pressed)

	
func _on_button_pressed():
	var new_tile_popup = preload("res://editors/map_editor/tile_color_picker.tscn").instantiate()
	get_tree().get_root().add_child(new_tile_popup)
	new_tile_popup.name = "add_tile_color_popup"
	new_tile_popup.parent_ref = self
	
