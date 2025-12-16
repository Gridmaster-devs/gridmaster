extends Control

enum GridView {
	STRATEGIC,
	TACTICAL
}
enum InputState {
	INTERACT,
	PAINT_TILE,
	PAINT_TACTICAL
}

@onready var tact_options = $"VBoxContainer/HBoxContainer/EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Tactical Options"
@onready var grid_view_button = $VBoxContainer/EditorPanel/TopVBox/ScrollContainer/ContentsVBox/HBoxContainer/grid_view_button
@onready var tact_lib = $"VBoxContainer/HBoxContainer/EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Tactical library/GridContainer"
@onready var new_tile_button = $"VBoxContainer/HBoxContainer/EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Tile library/GridContainer/VBoxContainer"
@onready var tile_lib = $"VBoxContainer/HBoxContainer/EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Tile library/GridContainer"
@onready var tile_grid = $VBoxContainer/HBoxContainer/SubViewControl/SubViewportContainer/SubViewport/TileGrid
@onready var background_grid = $VBoxContainer/HBoxContainer/SubViewControl/SubViewportContainer/SubViewport/BackgroundGrid
@onready var cam = $VBoxContainer/HBoxContainer/SubViewControl/SubViewportContainer/SubViewport/Camera2D
@onready var subview = $VBoxContainer/HBoxContainer/SubViewControl/SubViewportContainer/SubViewport
@onready var subview_cont = $VBoxContainer/HBoxContainer/SubViewControl/SubViewportContainer
@onready var save_dialog = $SaveDialog
@onready var load_dialog = $LoadDialog

var width: Dictionary = {}
var height: Dictionary = {}

#tile description: 
@onready var tile_name_ui = $"VBoxContainer/HBoxContainer/EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Current tile/Name/HBoxContainer/LineEdit"
@onready var tile_protection_ui = $"VBoxContainer/HBoxContainer/EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Current tile/Protection/HBoxContainer/LineEdit"
@onready var tile_movement_ui = $"VBoxContainer/HBoxContainer/EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Current tile/Movement/HBoxContainer/LineEdit"
@onready var tile_hiding_ui = $"VBoxContainer/HBoxContainer/EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Current tile/Hiding/HBoxContainer/LineEdit"
@onready var tile_image_ui = $"VBoxContainer/HBoxContainer/EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Current tile/image_hbox/TextureRect"
@onready var tile_dimage_ui = $"VBoxContainer/HBoxContainer/EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Current tile/dimage_hbox/TextureRect"
@onready var tile_tactical_map_ui = $"VBoxContainer/HBoxContainer/EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Current tile/Tactical map/HBoxContainer/LineEdit"

#a dictionary to arrays of nodes (each node is an added tile) 
var tile_lib_map: Dictionary = {}

#a dictionary to arrays of source ids (int)(each array represents a grid) 
var cur_internal_tile_grid_map: Dictionary = {}

#two dictionaries that map the source ids to their relevant information
var tile_strategic_map: Dictionary[int, StrategicTileInformation] = {}
var tile_tactical_map: Dictionary[int, TacticalTileInformation] = {}

#a dictionary mapping to callables that are called when swapped to that grid_view
var tile_grid_swap_callables_map: Dictionary = {}

#maps sourceids of strategic tiles to corresponding tactical grids
var tactical_grid_strategic_tile_map: Dictionary[int, String] = {}

#maps tactical grid names to corresponding tactical grids
var tactical_grid_map: Dictionary[String, Grid] = {}

var tactical_grid_button_map: Dictionary[String, Node] = {}

var tactical_grid_texture_map: Dictionary[String, Texture2D] = {}

#other
var cur_tactical_grid_name = ""
var dragging = false
const default_atlas_cord := Vector2i(0,0)
var cur_source := -1
var cur_gw := GridView.STRATEGIC
var input_state: InputState = InputState.PAINT_TILE
var highlight_id = 2
var default_bg_id = 1


func remove_tactical_grid(tact_grid_name: String): 
	#erase the connection to strategic tiles
	var keys_to_remove: Array = []
	for key in tactical_grid_strategic_tile_map.keys():
		if tactical_grid_strategic_tile_map[key] == tact_grid_name:
			keys_to_remove.append(key)
	for key in keys_to_remove:
		tactical_grid_strategic_tile_map.erase(key)
	#erase the button from ui
	if tactical_grid_button_map.has(tact_grid_name): 
		tactical_grid_button_map[tact_grid_name].queue_free()
		tactical_grid_button_map.erase(tact_grid_name)
	#erase the tactical grid
	if tactical_grid_map.has(tact_grid_name): 
		tactical_grid_map.erase(tact_grid_name)

func remove_cur_tactical_grid():
	remove_tactical_grid(cur_tactical_grid_name)
	change_input_state(InputState.PAINT_TILE)
#setup functions
func setup_width_height(): 
	width[GridView.STRATEGIC] = 100
	height[GridView.STRATEGIC] = 100
	width[GridView.TACTICAL] = 10
	height[GridView.TACTICAL] = 10
func setup_internal_tile_grid_map():
	for gw in GridView.values(): 
		cur_internal_tile_grid_map[gw] = []
		cur_internal_tile_grid_map[gw].resize(width[gw] * height[gw])
		cur_internal_tile_grid_map[gw].fill(-1)
func setup_tile_lib_map(): 
	tile_lib_map[GridView.STRATEGIC] = []
	tile_lib_map[GridView.TACTICAL] = [] 
func setup_swap_callables_map(): 
	tile_grid_swap_callables_map[GridView.STRATEGIC] = swap_strategic_callable
	tile_grid_swap_callables_map[GridView.TACTICAL] = swap_tact_callable
func save_strategic_grid(): 
	pass
func save_tactical_grid(tact_grid_name: String): 
	if tactical_grid_button_map.has(tact_grid_name): 
		tact_lib.remove_child(tactical_grid_button_map[tact_grid_name])
	var new_tact_button = create_tactical_grid_button(tact_grid_name)
	add_new_tactical_grid_to_library(new_tact_button)
	tactical_grid_button_map[tact_grid_name] = new_tact_button
	var new_grid: Grid = Grid.new()
	new_grid.grid = cur_internal_tile_grid_map[GridView.TACTICAL].duplicate()
	new_grid.width = width[GridView.TACTICAL]
	new_grid.height = height[GridView.TACTICAL]
	tactical_grid_map[tact_grid_name] = new_grid
	clear_external_grid()
	clear_internal_grid(GridView.TACTICAL)
	change_grid_view(GridView.STRATEGIC)
	cur_tactical_grid_name = ""


func create_tactical_grid_button_from_texture(tact_grid_name: String, tex: Texture2D): 
	# Build output image
	var img : Image = Image.create(width[cur_gw], height[cur_gw], false, Image.FORMAT_RGBA8)
	var tileset : TileSet = tile_grid.tile_set
	var vbox := VBoxContainer.new()
	var new_button := Button.new()
	new_button.icon = tex
	new_button.expand_icon = true
	new_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	new_button.custom_minimum_size = Vector2(84, 84)
	var tact_grid_script := load("res://scripts/map_editor_scripts/button_scripts/tactical_grid_button.gd")
	new_button.set_script(tact_grid_script)
	new_button.parent_ref = self
	new_button.tact_options = tact_options
	new_button.tactical_grid_name = tact_grid_name
	
	var label := Label.new()
	label.text = tact_grid_name
	label.custom_minimum_size = Vector2(84, 84)
	vbox.add_child(new_button)
	vbox.add_child(label)
	return vbox
	
func create_tile_lib_button(src: int, tex: Texture2D, name: String): 
	var vbox := VBoxContainer.new()
	var new_button := Button.new()
	new_button.icon = tex
	new_button.expand_icon = true
	new_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	new_button.custom_minimum_size = Vector2(84, 84)
	var tile_button_script := load("res://scripts/map_editor_scripts/button_scripts/tile_button_script.gd")
	new_button.set_script(tile_button_script)
	new_button.source = src
	new_button.parent_ref = self
	
	var label := Label.new()
	label.text = name
	label.custom_minimum_size = Vector2(84, 84)
	vbox.add_child(new_button)
	vbox.add_child(label)
	
	return vbox
	
func create_tactical_grid_button(tact_grid_name: String): 
	# Build output image
	var img : Image = Image.create(width[cur_gw], height[cur_gw], false, Image.FORMAT_RGBA8)
	var tileset : TileSet = tile_grid.tile_set
	# Loop pixels
	for y in range(height[cur_gw]):
		for x in range(width[cur_gw]):
			# Compute grid index
			var idx = width[cur_gw] * y + x
			var source_id = cur_internal_tile_grid_map[cur_gw][idx]
			if source_id < 0:
				# No tile → transparent
				img.set_pixelv(Vector2i(x, y), Color(0,0,0,0))
				continue
			# Get atlas coords for this tile
			var atlas_coords = default_atlas_cord
			# Get the tile source and its texture
			var source := tileset.get_source(source_id)
			if source == null:
				img.set_pixelv(Vector2i(x, y), Color(0,0,0,0))
				continue
			var texture : Texture2D = source.texture
			if texture == null:
				img.set_pixelv(Vector2i(x, y), Color(0,0,0,0))
				continue
			# Convert tile texture to image
			var tex_img : Image = texture.get_image()
			# Compute tile region in that image
			var tile_size : Vector2i = tileset.tile_size
			var region : Rect2i = Rect2i(atlas_coords * tile_size, tile_size)
			# Extract tile image
			var tile_img : Image = tex_img.get_region(region)
			# Average color over the tile area
			var avg_col : Color = Color(0,0,0,0)
			var total : int = tile_size.x * tile_size.y
			var sum_r : float = 0.0
			var sum_g : float = 0.0
			var sum_b : float = 0.0
			var sum_a : float = 0.0
			for ty in range(tile_size.y):
				for tx in range(tile_size.x):
					var c : Color = tile_img.get_pixel(tx, ty)
					sum_r += c.r
					sum_g += c.g
					sum_b += c.b
					sum_a += c.a
			avg_col.r = sum_r / total
			avg_col.g = sum_g / total
			avg_col.b = sum_b / total
			avg_col.a = sum_a / total
			# Set output pixel
			img.set_pixelv(Vector2i(x, y), avg_col)

	var tex : ImageTexture = ImageTexture.create_from_image(img)
	var vbox := VBoxContainer.new()
	var new_button := Button.new()
	new_button.icon = tex
	new_button.expand_icon = true
	new_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	new_button.custom_minimum_size = Vector2(84, 84)
	var tact_grid_script := load("res://scripts/map_editor_scripts/button_scripts/tactical_grid_button.gd")
	new_button.set_script(tact_grid_script)
	new_button.parent_ref = self
	new_button.tact_options = tact_options
	new_button.tactical_grid_name = tact_grid_name
	
	tactical_grid_texture_map[tact_grid_name] = tex.duplicate()
	
	var label := Label.new()
	label.text = tact_grid_name
	label.custom_minimum_size = Vector2(84, 84)
	vbox.add_child(new_button)
	vbox.add_child(label)
	return vbox


func load_internal_tile_grid(g: Grid, gw: GridView):
	cur_internal_tile_grid_map[gw].clear() #NOTE: unchanged changes are discarded, maybe edit later
	cur_internal_tile_grid_map[gw] = g.grid.duplicate()
	
func load_internal_grid(new_grid: Grid, gw: GridView): 
	load_internal_tile_grid(new_grid, gw)
	width[gw] = new_grid.width
	height[gw] = new_grid.height

func set_cur_selected_tactical_grid(grid_name: String): 
	cur_tactical_grid_name = grid_name

func load_tactical_grid(grid_name: String): 
	if tactical_grid_map.has(grid_name): 
		load_internal_grid(tactical_grid_map[grid_name], GridView.TACTICAL)
	else: 
		print("could not find tactical grid by name")
		width[GridView.TACTICAL] = 10
		height[GridView.TACTICAL] = 10
	change_grid_view(GridView.TACTICAL)

#swap callables
func swap_strategic_callable(): 
	tact_lib.visible = true 
	grid_view_button.text = "strategic"
	
func swap_tact_callable(): 
	tact_lib.visible = false 
	grid_view_button.text = "tactical"
	

#getters
func get_width(): 
	return width[cur_gw]
	
func get_height(): 
	return height[cur_gw]
#grid utility 
func clear_external_grid(): 
	tile_grid.clear()
	
func clear_internal_grid(gw: GridView): 
	cur_internal_tile_grid_map[gw].fill(-1)

func reload_external_grid(): 
	for y in range(height[cur_gw]): 
		for x in range(width[cur_gw]): 
			tile_grid.set_cell(Vector2i(x, y), cur_internal_tile_grid_map[cur_gw][y * width[cur_gw] + x], default_atlas_cord, 0) 
			
func clear_external_tile_lib(): 
	for child in tile_lib.get_children():
		if child != new_tile_button:
			tile_lib.remove_child(child)
	
func reload_tile_lib(): 
	for child in tile_lib_map[cur_gw]: 
		tile_lib.add_child(child)
		
func change_grid_view(gw: GridView): 
	#clear current grid, then we can change the grid view 
	#(so we don't clear old grid with parameters of new grid) 
	clear_external_grid() #clear the external grid
	cur_gw = gw #change current view to the one being changed to
	reload_external_grid() #reload the grid for that view from internal memory 
	clear_external_tile_lib() #clear the external tile library 
	reload_tile_lib() #reload the tile library from internal memory 
	background_grid.regenerate() #resize the grid to match view
	cur_source = -1 #forget current painting source
	tile_grid_swap_callables_map[cur_gw].call() #call the swap callables 

func change_grid_view_to_next(): 
	change_grid_view((cur_gw + 1) % GridView.size())
	

func add_new_tile_to_library(child: Node): 
	tile_lib.add_child(child)
	tile_lib_map[cur_gw].append(child)
func add_new_tile_to_internal_library(child: Node, gw_toadd: GridView): 
	tile_lib_map[gw_toadd].append(child)
func add_new_tactical_grid_to_library(child: Node): 
	tact_lib.add_child(child)

func resize_tile_grid_map(new_w: int, new_h: int): 
	var old_w = width[cur_gw]
	var old_h = height[cur_gw]
	var old = cur_internal_tile_grid_map[cur_gw].duplicate()
	cur_internal_tile_grid_map[cur_gw].resize(new_w * new_h)
	cur_internal_tile_grid_map[cur_gw].fill(-1)
	for y in range(min(old_h, new_h)):
		for x in range(min(old_w, new_w)):
			cur_internal_tile_grid_map[cur_gw][y * new_w + x] = old[y * old_w + x]
	

func update_tactical_highlight(): 
	var highlighted_sources = []
	for key in tactical_grid_strategic_tile_map.keys():
		var value = tactical_grid_strategic_tile_map[key]
		if value == cur_tactical_grid_name:
			highlighted_sources.append(key)
	for y in range(height[GridView.STRATEGIC]):
		for x in range(width[GridView.STRATEGIC]): 
			var cur_id = cur_internal_tile_grid_map[GridView.STRATEGIC][width[GridView.STRATEGIC] * y + x]
			if highlighted_sources.has(cur_id): 
				background_grid.set_cell(Vector2i(x, y), highlight_id, Vector2i(0,0), 0)
			else: 
				background_grid.set_cell(Vector2i(x, y), default_bg_id, Vector2i(0,0), 0)
			

func change_input_state(inpt: InputState): 
	input_state = inpt
	if input_state == InputState.PAINT_TACTICAL:
		update_tactical_highlight()
	else: 
		cur_tactical_grid_name = ""
		background_grid.regenerate()


func _ready():
	setup_width_height()
	setup_internal_tile_grid_map()
	setup_tile_lib_map()
	setup_swap_callables_map()
	background_grid.regenerate()
	save_dialog.file_selected.connect(save_game_map)
	load_dialog.file_selected.connect(load_game_map)

func resize(x: int, y: int): 
	resize_tile_grid_map(x, y)
	width[cur_gw] = x
	height[cur_gw] = y
	background_grid.regenerate()

func get_tile_position() -> Vector2i:
	var subview_pos = subview.get_mouse_position()
	var world_pos = (subview_pos / cam.zoom) + cam.position
	var tile_pos = tile_grid.local_to_map(tile_grid.to_local(world_pos))
	return tile_pos

func is_mouse_blocking() -> bool: 
	if get_viewport().gui_get_hovered_control() != subview_cont: 
		return true
	return false

func handle_paint_tile(): 
	var tile_pos = get_tile_position()
	if background_grid.get_cell_source_id(tile_pos) != -1:
		tile_grid.set_cell(tile_pos, cur_source, default_atlas_cord, 0)
		cur_internal_tile_grid_map[cur_gw][tile_pos.y * width[cur_gw] + tile_pos.x] = cur_source
		dragging = true
	else:
		dragging = false

func handle_paint_tactical(): 
	var tile_pos = get_tile_position()
	if background_grid.get_cell_source_id(tile_pos) != -1:
		var source_id = tile_grid.get_cell_source_id(tile_pos)
		if cur_tactical_grid_name != "" && source_id != -1: 
			if tactical_grid_strategic_tile_map.get(source_id, "") == cur_tactical_grid_name: 
				tactical_grid_strategic_tile_map[source_id] = ""
			else: 
				tactical_grid_strategic_tile_map[source_id] = cur_tactical_grid_name
			update_tactical_highlight()

func handle_interact():
	var tile_pos = get_tile_position()
	var cur_tile_source = cur_internal_tile_grid_map[cur_gw][tile_pos.y * width[cur_gw] + tile_pos.x]
	if cur_tile_source == -1: 
		tile_name_ui.text = ""
		tile_hiding_ui.text = ""
		tile_protection_ui.text = ""
		tile_tactical_map_ui.text = ""
		tile_movement_ui.text = ""
		tile_image_ui.texture = Texture2D.new()
	else:
		if cur_gw == GridView.STRATEGIC: 
			var cur_tile = tile_strategic_map.get(cur_tile_source, StrategicTileInformation.new())
			tile_name_ui.text = cur_tile.name
			tile_hiding_ui.text = str(cur_tile.hiding)
			tile_protection_ui.text = str(cur_tile.protection)
			tile_movement_ui.text = str(cur_tile.movement)
			tile_image_ui.texture = cur_tile.texture
			tile_tactical_map_ui.text = tactical_grid_strategic_tile_map.get(cur_tile_source, "")
		else: 
			var cur_tile = tile_tactical_map.get(cur_tile_source, TacticalTileInformation.new())
			tile_name_ui.text = cur_tile.name
			tile_hiding_ui.text = str(cur_tile.hiding)
			tile_protection_ui.text = str(cur_tile.protection)
			tile_movement_ui.text = str(cur_tile.movement)
			tile_image_ui.texture = cur_tile.texture
			tile_tactical_map_ui.text = tactical_grid_strategic_tile_map.get(cur_tile_source, "")

func _input(event):
	if is_mouse_blocking(): 
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed == true:
			if input_state == InputState.INTERACT: 
				handle_interact()
			elif input_state == InputState.PAINT_TILE:
				handle_paint_tile()
			else: 
				handle_paint_tactical()
		else:
			dragging = false
	if dragging and event is InputEventMouseMotion:
		if input_state == InputState.PAINT_TILE:
			handle_paint_tile()

func load_sources(tile_map_layer: TileMapLayer) -> Dictionary[int, Texture2D]:
	var result: Dictionary[int, Texture2D] = {}

	var tileset: TileSet = tile_map_layer.tile_set
	if tileset == null:
		return result

	var source_count := tileset.get_source_count()
	for i in range(source_count):
		var source_id := tileset.get_source_id(i)
		var source := tileset.get_source(source_id)

		if source is TileSetAtlasSource:
			var atlas := source as TileSetAtlasSource
			result[source_id] = atlas.texture

	return result
	



func save_game_map(path: String): 
	var new_game_map = GameMap.new()
	new_game_map.grid = Grid.new()
	new_game_map.grid.height = height[GridView.STRATEGIC]
	new_game_map.grid.width = width[GridView.STRATEGIC]
	new_game_map.grid.grid = cur_internal_tile_grid_map[GridView.STRATEGIC]
	new_game_map.tactical_grid_strategic_tile_map = tactical_grid_strategic_tile_map
	new_game_map.tactical_grid_map = tactical_grid_map
	new_game_map.tactical_tile_information_map = tile_tactical_map
	new_game_map.strategic_tile_information_map = tile_strategic_map
	new_game_map.texture_map = load_sources(tile_grid)
	new_game_map.tactical_grid_thumbnail_texture_map = tactical_grid_texture_map
	
	var err := ResourceSaver.save(new_game_map, path)
	if err != OK:
		push_error("Failed to save GameMap: %s" % err)
	


func clear_tile_libs():
	pass
func create_tactical_grid_lib(): 
	for key in tactical_grid_map: 
		var new_tact_button = create_tactical_grid_button_from_texture(key, tactical_grid_texture_map[key])
		add_new_tactical_grid_to_library(new_tact_button)
		tactical_grid_button_map[key] = new_tact_button
		
func create_tile_libs(texs: Dictionary[int, Texture2D]):
	for key in tile_strategic_map: 
		var vbox = create_tile_lib_button(key, texs[key], tile_strategic_map[key].name)
		add_new_tile_to_internal_library(vbox, GridView.STRATEGIC)
	for key in tile_tactical_map: 
		var vbox = create_tile_lib_button(key, texs[key], tile_tactical_map[key].name)
		add_new_tile_to_internal_library(vbox, GridView.TACTICAL)
	
func add_sources_to_external(texs: Dictionary[int, Texture2D]): 
	for texid in texs: 
		var source = TileSetAtlasSource.new()
		source.texture = texs[texid]
		source.texture_region_size = Vector2i(64, 64)
		source.create_tile(Vector2i(0,0))
		tile_grid.tile_set.add_source(source)


func load_from_data(gm: GameMap):
	tactical_grid_strategic_tile_map = gm.tactical_grid_strategic_tile_map
	tactical_grid_map = gm.tactical_grid_map
	tile_tactical_map = gm.tactical_tile_information_map
	tile_strategic_map = gm.strategic_tile_information_map
	var source_id_textures = gm.texture_map
	tactical_grid_texture_map = gm.tactical_grid_thumbnail_texture_map
	
	height[GridView.STRATEGIC] = gm.grid.height
	width[GridView.STRATEGIC] = gm.grid.width
	cur_internal_tile_grid_map[GridView.STRATEGIC] = gm.grid.grid
	
	create_tactical_grid_lib()
	create_tile_libs(source_id_textures)
	add_sources_to_external(source_id_textures)
	change_grid_view(GridView.STRATEGIC)
	

func load_game_map(path: String):
	if (ResourceLoader.exists(path)):
		var data : GameMap = ResourceLoader.load(path) as GameMap
		load_from_data(data) 
	
	
	
	
	
