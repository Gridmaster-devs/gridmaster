extends Control

var dragging := false
var drag_offset := Vector2.ZERO
var parent_ref = null
var cur_source = 0
var cur_texture = Texture.new()


func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				drag_offset = get_global_mouse_position() - global_position
			else:
				dragging = false
	elif event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position() - drag_offset


func addSourceToTileMap(): 
	var tile_set = parent_ref.tile_grid.tile_set
	var source = TileSetAtlasSource.new()

	if cur_texture != null: 
		source.texture = cur_texture
	else: 
		var img = Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color.BLACK)
		source.texture = ImageTexture.create_from_image(img)
	source.texture_region_size = Vector2i(64, 64)
	source.create_tile(Vector2i(0,0))
	cur_source = tile_set.add_source(source)

func addNewTile(tile_name: String, protection: int, hiding: int, movement: int): 
	addSourceToTileMap()
	
	var vbox := VBoxContainer.new()
	var new_button := Button.new()
	new_button.icon = cur_texture
	new_button.expand_icon = true
	new_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	new_button.custom_minimum_size = Vector2(84, 84)
	var tile_button_script := load("res://editor/scripts/map_editor_scripts/button_scripts/tile_button_script.gd")
	new_button.set_script(tile_button_script)
	new_button.source = cur_source
	new_button.parent_ref = parent_ref

	
	var label := Label.new()
	label.text = tile_name
	label.custom_minimum_size = Vector2(84, 84)
	vbox.add_child(new_button)
	vbox.add_child(label)
	
	if parent_ref.cur_gw == parent_ref.GridView.STRATEGIC: 
		parent_ref.tile_strategic_map[cur_source] = \
			StrategicTileInformation.new(cur_source, tile_name, 
			protection, movement, hiding, cur_texture)
	else: 
		parent_ref.tile_tactical_map[cur_source] = \
			TacticalTileInformation.new(cur_source, tile_name, 
			protection, movement, hiding, cur_texture)
	
	
	parent_ref.add_new_tile_to_library(vbox)
	self.queue_free()
	
