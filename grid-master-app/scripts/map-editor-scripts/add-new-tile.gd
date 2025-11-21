extends Node


@onready var tile_map = get_node("/root/MapEditor/TileMapLayer")
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
	tile_set.add_source(source)
	get_tree().get_root().get_node("create_new_tile_popup").queue_free()
