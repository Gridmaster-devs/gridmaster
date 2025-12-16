extends Node

#get_node("/root/MapEditor/VBoxContainer/HBoxContainer/SubViewControl/SubViewportContainer/SubViewport/TileGrid")
#get_node("/root/MapEditor/VBoxContainer/HBoxContainer/EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Tile library/GridContainer")
@onready var color_picker = $"../ColorPicker"
@onready var parent_ref = $"../../../../../.."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.pressed.connect(_on_button_pressed)

	
func _on_button_pressed():
	var tile_set = parent_ref.parent_ref.parent_ref.tile_grid.tile_set 
	var source = TileSetAtlasSource.new()
	var width = 64
	var height = 64 
	var color = color_picker.color
	
	var img = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	img.fill(color)
	
	var cur_tex = ImageTexture.create_from_image(img)
	source.texture = cur_tex
	parent_ref.parent_ref.cur_texture = cur_tex
	source.texture_region_size = Vector2i(64, 64)
	source.create_tile(Vector2i(0,0))
	parent_ref.parent_ref.cur_source = tile_set.add_source(source)
	parent_ref.queue_free()
	
	
