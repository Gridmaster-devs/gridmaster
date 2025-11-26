extends Node


@onready var tile_map = get_node("/root/MapEditor/VBoxContainer/HBoxContainer/SubViewControl/SubViewportContainer/SubViewport/TileMapLayer")
@onready var tile_lib = get_node("/root/MapEditor/VBoxContainer/HBoxContainer/EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Tile library/GridContainer")
@onready var color_picker = $"../ColorPicker"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.pressed.connect(_on_button_pressed)

	
func _on_button_pressed():
	var tile_set = tile_map.tile_set 
	var source = TileSetAtlasSource.new()
	var width = 64
	var height = 64 
	var color = color_picker.color
	
	var img = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	img.fill(color)

	source.texture = ImageTexture.create_from_image(img)
	source.texture_region_size = Vector2i(64, 64)
	source.create_tile(Vector2i(0,0))
	var cur_source = tile_set.add_source(source)
	get_tree().get_root().get_node("create_new_tile_popup").queue_free()
	
	var btn_tex := ImageTexture.create_from_image(img)

	var stylebox := StyleBoxTexture.new()
	stylebox.texture = btn_tex

	var new_button := Button.new()
	new_button.text = "New Tile"
	new_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_button.add_theme_stylebox_override("normal", stylebox)
	new_button.add_theme_stylebox_override("hover", stylebox)
	new_button.add_theme_stylebox_override("pressed", stylebox)
	new_button.set_script(load("res://scripts/map-editor-scripts/side_panel_scripts/tile_button_script.gd"))
	new_button.source = cur_source
	
	tile_lib.add_child(new_button)
	
