extends Node
class_name TileDescriptor

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func clear() -> void: 
	for child in get_children(): 
		child.queue_free()

#generates the tile description UI matching the tile attributes in tile_data
func update(tile_attribute_types: Dictionary[String, Variant]) -> void: 
	clear()
	for key in tile_attribute_types.keys(): 
		var value = tile_attribute_types[key]
		var tile_attribute_hbox = HBoxContainer.new()
		tile_attribute_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var tile_attribute_name_ui = Label.new()
		tile_attribute_name_ui.text = key 
		tile_attribute_name_ui.custom_minimum_size = Vector2(80, 0)
		
		var tile_attribute_value_ui: Node
		
		##checks what type of attribute the current value in the dictionary is
		##and approriately creates a matching ui element
		if value is int or value is float or value is String:
			tile_attribute_value_ui = _create_line_edit()
			tile_attribute_value_ui.text = str(value)
		elif value is Texture2D:
			tile_attribute_value_ui = _create_texture_rect()
			tile_attribute_value_ui.texture = value
			
		tile_attribute_hbox.add_child(tile_attribute_name_ui)
		tile_attribute_hbox.add_child(tile_attribute_value_ui)
		self.add_child(tile_attribute_hbox)
		

func _create_line_edit() -> LineEdit: 
		var line_edit = LineEdit.new()
		line_edit.placeholder_text = ""
		line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		return line_edit
func _create_texture_rect() -> TextureRect:
	var texture_rect := TextureRect.new()
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texture_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return texture_rect
	
