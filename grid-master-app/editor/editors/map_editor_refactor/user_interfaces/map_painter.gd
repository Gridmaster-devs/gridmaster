class_name MapPainter
extends Control

@onready var _content_vbox: VBoxContainer = $HBoxContainer/RightPanel/TopVBox/ScrollContainer/ContentsVBox
@onready var _background_grid: BackgroundTileMap = $HBoxContainer/SubViewControl/SubViewportContainer/SubViewport/BackgroundGrid
@onready var _sub_viewport: SubViewport = $HBoxContainer/SubViewControl/SubViewportContainer/SubViewport
@onready var _sub_view_container: SubViewportContainer = $HBoxContainer/SubViewControl/SubViewportContainer
@onready var _camera: Camera2D = $HBoxContainer/SubViewControl/SubViewportContainer/SubViewport/Camera2D
@onready var _erase_button: Button = $HBoxContainer/LeftPanel/TopVBox/ScrollContainer/ContentsVBox/VBoxContainer/EraseButton
@onready var _interact_button: Button = $HBoxContainer/LeftPanel/TopVBox/ScrollContainer/ContentsVBox/VBoxContainer/InteractButton
@onready var _tile_descriptor: TileDescriptor = $HBoxContainer/RightPanel/TopVBox/ScrollContainer/ContentsVBox/TileDescriptorContainer/TileDescriptor
@onready var _settings_button: Button = $HBoxContainer/LeftPanel/TopVBox/ScrollContainer/ContentsVBox/SSLVbox/SettingsButton

enum InputState {
	INTERACT,
	ERASE,
	PAINT
}


##GENERAL DATA
var layers: Array[MapLayer]

##PAINT LIBRARY DATA
#maps each library name to an array of Dictionary[String, Variant]
#each entry in the array is a library item (a button) 
#each dictionary defines the values of that lib item (the values it will set when used) 
var _lib_items_data: Dictionary[String, Array] = {}
#Maps libraries with their names
var _paint_libraries: Dictionary[String, PaintLibrary]


##ATTRIBUTE DATA
#Tells the painter which attribute in tile attirbute list is used 
#to display the tile on the map
var _tile_texture_id: String
#the unique identifier for a tile type
var _tile_id: String

#Tile textures saved as attributes need to be assigned to sources in tileMapLayer class 
#maps to an int, which is the source id for the texture within the tileMapLayer
var _tile_texture_tileatlas_source_map: Dictionary[Texture2D, int]


##Variables used for painting 
#current input state, decides what clicking on tiles does
var _input_state = InputState.INTERACT
#tilemap layer painting stuff
const _PAINT_TILE_ATLAS_CORD: Vector2i = Vector2i(0,0)
#refers to the id of the source texture being used to paint the tiles
var _paint_tile_value = -1
#same as above, but for background grid tileatlast sources
var _paint_highlight_value = 0
var _highlight = false
#attribute painting
#These lists are used for defining which attributes are changed and how when painting
var _overwrite_attribute_list: Dictionary[String, Variant]
var _addable_attribute_list: Dictionary[String, Variant]
#state variable for m1 being pressed while painting
var _dragging = false
#when drag painting, tracks the previously painted tile, 
#so the same tile wont be painted twice in a row
var _dragging_previous: Vector2i = Vector2i(-1, -1)

##Ready function and UI signal connections
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_connect_ui()

#UI CONNECTION
func _connect_ui() -> void: 
	_interact_button.pressed.connect(_change_state.bind(InputState.INTERACT))
	_erase_button.pressed.connect(_change_state.bind(InputState.ERASE))
	_settings_button.pressed.connect(open_settings_popup)
	
##INITIALIZATION
#initializes an empty map
#tile_attribute_types is used for generating the descriptor UI later
#tile_texture_id refers to the texture id that will be used to paint the tileMapLayer
#tile_id is the identifier to identify unique tile types
func init_painter(tile_texture_id: String, tile_id: String, width: int, height: int) -> void: 
	_background_grid.gen_map(width, height)
	_tile_texture_id = tile_texture_id
	_tile_id = tile_id
	#initialize the attribute grid
	_update_attribute_grid(width, height)


##reciever functions for library button presses
#add function will change the add attributes 
#overwrite will change the overwrite attirbutes
#these two attirbute lists are responsible for painting tiles on the grid 
func on_lib_item_pressed(addable: Dictionary[String, Variant], 
					  overwrite: Dictionary[String, Variant], highlight: bool) -> void: 
	#variable just to make it clear and so all that
	#the variable settings are in one spot
	var old_highlight_state = _highlight
	#set new variable states
	_addable_attribute_list = addable
	_overwrite_attribute_list = overwrite
	_highlight = highlight
	_change_state(InputState.PAINT)
	#checks if the incoming data contains the paint texture 
	#(used for changing appearance of tiles)
	if overwrite.has(_tile_texture_id): 
		var tile_tex = overwrite[_tile_texture_id]
		if !_tile_texture_tileatlas_source_map.has(tile_tex):
			_add_new_atlas_source(tile_tex)
		_paint_tile_value = _tile_texture_tileatlas_source_map[tile_tex]
	else: 
		_paint_tile_value = -1
	#highlighting 
	#clear previous highlight by regenerating the background grid
	#if there was highlighting before
	if old_highlight_state:
		_background_grid.regenerate(_get_width(), _get_height())
	if highlight:
		#highlight freshly
		_highlight_with_attributes(addable, overwrite)

func remove_lib_item(lib_name: String, item_id: String, item_id_value: Variant) -> void:
	if _lib_items_data.has(lib_name): 
		var lib_items = _lib_items_data[lib_name]
		for item in lib_items:
			if item is Dictionary:
				if item.has(item_id) and item[item_id] == item_id_value: 
					#remove the matching tiles from the map
					_remove_attributes(item, item_id, item_id_value)
					#remove the item from library
					lib_items.erase(item)
					_paint_libraries[lib_name].initialize_lib_items(lib_items)

##State incrementing / decremeneting functions
#adds a new source to tileMapLayer
func _add_new_atlas_source(tex: Texture2D) -> void:
	var tile_set = _tile_grid.tile_set
	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(Global.tile_width, Global.tile_height)
	source.create_tile(Vector2i(0,0))
	_tile_texture_tileatlas_source_map[tex] = tile_set.add_source(source)

#adds a new library item to a specific library
func add_new_lib_item(data: Dictionary[String, Variant], lib_name: String):
	if !_paint_libraries.has(lib_name):
		return
	if !_lib_items_data.has(lib_name):
		_lib_items_data[lib_name] = Array()
	#only add the item if one with the unique ID doesnt exist already
	var item_id = _paint_libraries[lib_name].get_item_id()
	#if the new item doesn't have the unique identifier we return out
	if !data.has(item_id):
		return
	if !_dict_array_has_item(_lib_items_data[lib_name], item_id, data[item_id]):
		_lib_items_data[lib_name].append(data)
		_paint_libraries[lib_name].initialize_lib_items(_lib_items_data[lib_name])

#adds a new library to the map painter (look up PaintLibrary)
func add_library(lib_name: String, overwrite_data: Dictionary[String, Variant], 
				addable_data: Dictionary[String, Variant], preview_texture_id: String, name_id: String, 
				highlight: bool = false, lib_new_button_callback: Callable = Callable()) -> void: 
	var _tile_library: PaintLibrary = preload("res://editor/editors/map_editor_refactor/user_interfaces/paint_library/paint_library.tscn").instantiate()
	_content_vbox.add_child(_tile_library)
	##CAN USE AFTER ADDED TO TREE
	#init the library
	_tile_library.init(lib_name, preview_texture_id, name_id, 
						overwrite_data, addable_data, highlight, lib_new_button_callback)
	#add the library to the library map, so we can refrence it later
	_paint_libraries[lib_name] = (_tile_library)
	#connect library signals
	_tile_library.lib_item_pressed.connect(on_lib_item_pressed)
	_tile_library.lib_item_removed.connect(remove_lib_item)
	#as map painter contains the items for the libs, 
	#set the array of items of this lib to an empty one (basically init it) 
	_lib_items_data[lib_name] = []


##IMPORT / EXPORT
##AND STATE UPDATING FUNCTIONS (for loading and reloading the state of the map painter) 

#imports a map from a "MapPainterRes" resource
#The resource has to be exported from the same type of MapPainter
func import(path: String) -> void:
	var res: MapPainterRes = ResourceLoader.load(path) as MapPainterRes
	import_from_resource(res)

func import_from_resource(res: MapPainterRes) -> void: 
	_attribute_grid = res.get_attribute_grid()
	_lib_items_data = res.get_lib_items()
	#will update the background grid to match in size to attribute grid
	_background_grid.regenerate(_attribute_grid.width, _attribute_grid.height)
	#will update the tileMapLayer with _attribute_grid
	_update_tile_map()
	#updates the libraries, creates them basically based on _lib_items_data
	_update_libraries()

#exports the map as a resource "MapPainterRes"
#this export will be only readable by the same type of MapPainter that exported it
func export(path: String) -> void: 
	var res: MapPainterRes = MapPainterRes.new()
	res.init(_attribute_grid, _lib_items_data)
	var err = ResourceSaver.save(res, path)
	if err != OK:
		print("error", err)

func export_as_resource() -> MapPainterRes: 
	var res: MapPainterRes = MapPainterRes.new()
	res.init(_attribute_grid, _lib_items_data)
	return res

#fully reloads the attribute grid and tilemaplayers based on new dimension
#preserves old data 
func update_grids(width: int, height: int) -> void: 
	_update_attribute_grid(width, height)
	_background_grid.regenerate(width, height)
	_update_tile_map()

#completely resets the grids, clears them and 
#doesnt preserve data (cmp to updateGrids()) 
func reset_grids(width: int, height: int) -> void: 
	_reset_attribute_grid(width, height)
	_background_grid.regenerate(width, height)
	_update_tile_map()

#initializes or resizes the grid
#meaning that it will keep existing data in _attribute_grid if it exists
func _update_attribute_grid(width: int, height: int) -> void: 
	var new_attribute_grid = Array2D.new()
	new_attribute_grid.init(width, height)
	for x in width: 
		for y in height: 
			var new_val: Dictionary[String, Variant] = {}
			new_attribute_grid.setItem(x, y, new_val)
	for x in min(_attribute_grid.width, width): 
		for y in min(_attribute_grid.height, height):
			new_attribute_grid.setItem(x, y, _attribute_grid.getItem(x, y))
	_attribute_grid = new_attribute_grid

#totally clears the attribute grid and initializes it with new dimensions
func _reset_attribute_grid(width: int, height: int) -> void: 
	_attribute_grid = Array2D.new()
	_attribute_grid.init(width, height)
	for x in width: 
		for y in height: 
			var attribute_list: Dictionary[String, Variant] = {}
			_attribute_grid.setItem(x, y, attribute_list)

#callback from settings popup (called from popup manager) 
#updates the state of the painter, calls updateGrids() 
func update_settings(settings: Dictionary[String, Variant]) -> void:
	var new_width = _get_width()
	var new_height = _get_height()
	if settings.has("width"): 
		new_width = settings["width"]
	if settings.has("height"):
		new_height = settings["height"]
	update_grids(new_width, new_height)

#updates tile map layer based on attribute grid
#clears and sets textures again
#will add new source ids if missign textures 
func _update_tile_map() -> void: 
	_tile_grid.clear()
	for x in _attribute_grid.width: 
		for y in _attribute_grid.height: 
			if _attribute_grid.getItem(x, y).has(_tile_texture_id): 
				var tex = _attribute_grid.getItem(x, y)[_tile_texture_id]
				if !_tile_texture_tileatlas_source_map.has(tex):
					_add_new_atlas_source(tex)
				_tile_grid.set_cell(Vector2i(x, y), _tile_texture_tileatlas_source_map[tex], _PAINT_TILE_ATLAS_CORD)

#update all libraries with _lib_items_data
func _update_libraries() -> void: 
	for lib_name in _paint_libraries.keys(): 
		_paint_libraries[lib_name].initialize_lib_items(_lib_items_data[lib_name])

#reloads a library completely from external data
func sync_library(data: Array, lib_name: String) -> void:
	#if lib doesnt exist we cant do anything
	if !_paint_libraries.has(lib_name):
		return
	var item_id = _paint_libraries[lib_name].get_item_id()
	#check if the incoming data contains has every lib item that exits already
	#remove lib item also removes the attributes from the grid
	for item in _lib_items_data[lib_name]: 
		if !_dict_array_has_item(data, item_id, item[item_id]):
			remove_lib_item(lib_name, item_id, item[item_id])
	#we will add every item to the library
	#keep in mind that "add_new_lib_item" does nothing if the item already exists in the lib
	for item in data:
		add_new_lib_item(item, lib_name)
	_update_tile_map()

#copies another attribute_grid, preserves "exclude" and doesnt overwrite them
func sync_attribute_grid(data: Array2D, exclude: Array[String]) -> void: 
	#copy the "exclude" key value pairs from _attribute_grid to new_grid
	var new_grid = data.duplicate_deep()
	for x in min(_attribute_grid.width, new_grid.width):
		for y in min(_attribute_grid.height, new_grid.height):
			if new_grid.getItem(x, y) is not Dictionary:
				var empty_dict: Dictionary[String, Variant] = {}
				new_grid.setItem(x, y, empty_dict)
			var tile = _attribute_grid.getItem(x, y)
			var new_tile = new_grid.getItem(x, y)
			for key in exclude: 
				if tile.has(key):
					new_tile[key] = tile[key]
	_attribute_grid = new_grid
	update_grids(_attribute_grid.width, _attribute_grid.height)


##DYNAMIC flow functions
#simple function to change current input state
func _change_state(new_state: InputState) -> void:
	_input_state = new_state
	if new_state != InputState.PAINT && _highlight:
		_highlight = false
		_background_grid.regenerate(_get_width(), _get_height())


#highlights every tile in background grid 
#whose attribute lists have the equal keys and values
func _highlight_with_attributes(addable: Dictionary[String, Variant], 
								overwrite: Dictionary[String, Variant]) -> void: 
	for x in _attribute_grid.width:
		for y in _attribute_grid.height: 
			if (_has_all_keys_and_values(overwrite, _attribute_grid.getItem(x, y)) and 
				_has_all_keys_and_values(addable, _attribute_grid.getItem(x, y))):
					_background_grid.set_cell(Vector2i(x, y), _paint_highlight_value, _PAINT_TILE_ATLAS_CORD)


##INPUT FUNCTIONS
##HANDLES INTERACT, PAINTING AND ERASE
##BASED ON THE ENUM "InputState" 
#high level input handling function for the painter
#checks if the mouse is in paint area and then calls 
#the corresponding input handler depending on the current state
func _input(event: InputEvent) -> void:
	if !_mouse_on_map(): 
		return
	else: 
		if _input_state == InputState.INTERACT:
			_handle_interact_input(event)
		else: 
			_handle_paint_input(event)

#helper that handles input for mouse inputs when painting
#checks if the input is to paint and if the hovered tile is valid then calls "_paintTile" 
#_paintTile function will check what state the painter is in and how the tile should be painted
func _handle_paint_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed == true:
			var hovered_tile = _get_hovered_tile()
			if(_is_in_bounds(hovered_tile)):
				if _input_state == InputState.ERASE:
					_erase_tile(hovered_tile)
				elif _input_state == InputState.PAINT:
					_paint_tile(hovered_tile)
				_dragging_previous = hovered_tile
				_dragging = true
		else:
			_dragging = false
			_dragging_previous = Vector2i(-1, -1)
	elif _dragging and event is InputEventMouseMotion: 
			var hovered_tile = _get_hovered_tile()
			if _dragging_previous == hovered_tile:
				return
			if(_is_in_bounds(hovered_tile)):
				if _input_state == InputState.ERASE:
					_erase_tile(hovered_tile)
				elif _input_state == InputState.PAINT:
					_paint_tile(hovered_tile)
				_dragging_previous = hovered_tile

#handles the interact input state
#will update the _tile_descriptor ui element on the right panel 
#if clicked on a tile that has attributes
func _handle_interact_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed == true:
			var hovered_tile = _get_hovered_tile()
			if(_is_in_bounds(hovered_tile)):
				var tile_data = _attribute_grid.getItem(hovered_tile.x, hovered_tile.y)
				_tile_descriptor.update(tile_data)
					

#will be calld if PAINT state, 
#will set the attributes based on overwrite list and add list
#Will set the 
func _paint_tile(hovered_tile: Vector2i) -> void:
	#paint value will be -1 if we are not currently paiting tile appearances
	#meaning that we are currently only painting attributes
	if _paint_tile_value != -1:
		_tile_grid.set_cell(hovered_tile, _paint_tile_value, _PAINT_TILE_ATLAS_CORD)
	if _highlight:
		_background_grid.set_cell(hovered_tile, _paint_highlight_value, _PAINT_TILE_ATLAS_CORD)
	for key in _overwrite_attribute_list: 
		_attribute_grid.getItem(hovered_tile.x, hovered_tile.y)[key] = _overwrite_attribute_list[key]
	for key in _addable_attribute_list: 
		var addable_value = _addable_attribute_list[key]
		if !_attribute_grid.getItem(hovered_tile.x, hovered_tile.y).has(key):
			_attribute_grid.getItem(hovered_tile.x, hovered_tile.y)[key] = []
		var grid_value = _attribute_grid.getItem(hovered_tile.x, hovered_tile.y)[key]
		if grid_value is Array:
			grid_value.append(addable_value)
	
#if ERASE -> changes the hovered tile source id to -1 so it becomes blank
func _erase_tile(hovered_tile: Vector2i) -> void: 
	var empty_attribute_list: Dictionary[String, Variant] = {}
	_attribute_grid.setItem(hovered_tile.x, hovered_tile.y, empty_attribute_list)
	_tile_grid.set_cell(hovered_tile, -1)


##POPUPS
func open_settings_popup() -> void: 
	var settings_popup: SettingsPopup = preload("res://editor/editors/map_editor_refactor/popup_windows/settings_popup.tscn").instantiate()
	get_tree().call_group("map_painter_popup_manager", "add_new_popup", settings_popup, settings_popup.get_popup_name())
	settings_popup.init(_generate_settigns_dict())

#popup manager callback, returns true if map painter is active
func is_active() -> bool: 
	return is_visible_in_tree() and visible


##utility functions: 
#removes tile from the map with specific tile_id value
#updates th _attribute_grid
#then updates the tile_map based on the attribute grid
func _remove_tiles(tile_id_value: Variant) -> void: 
	for x in _get_width():
		for y in _get_height():
			var tile_attributes = _attribute_grid.getItem(x, y)
			if tile_attributes.has(_tile_id) and tile_attributes[_tile_id] == tile_id_value:
				var empty_attribute_list: Dictionary[String, Variant] = {}
				_attribute_grid.setItem(x, y, empty_attribute_list)
	_update_tile_map()

#removes every attribute from a tile that is in data
#only removes from tiles that match item_id with item_id_value
#DONT LOOK HERE TODO: refactor this function to be more clear
func _remove_attributes(data: Dictionary[String, Variant], item_id: String, item_id_value: Variant) -> void: 
	for x in _get_width():
		for y in _get_height():
			var tile_attributes = _attribute_grid.getItem(x, y)
			if tile_attributes is Dictionary:
				#if the tile is identified as the tile type in question
				if (tile_attributes.has(item_id) and 
					(tile_attributes[item_id] is Array and tile_attributes[item_id].has(item_id_value) or 
					tile_attributes[item_id] is not Array and tile_attributes[item_id] == item_id_value)):
						#remove every key that exists in the data from the tile
						for key in data.keys(): 
							if tile_attributes.has(key):
								var tile_val = tile_attributes[key]
								if tile_val is Array: 
									while tile_val.has(data[key]):
										tile_val.erase(data[key])
								elif data[key] == tile_val:
									tile_attributes.erase(key)
	_update_tile_map()

#checks if a library already has an item with the specific id 
func _dict_array_has_item(data: Array, item_id: String, id_value: Variant) -> bool: 
	for item in data:
		if item is Dictionary:
			if item.has(item_id) and item[item_id] == id_value:
				return true
	return false

func _generate_settigns_dict() -> Dictionary[String, Variant]:
	return {"width": _attribute_grid.width, "height": _attribute_grid.height}
													
#checks if the cursor is not in the paint area 
func _mouse_on_map() -> bool: 
	if get_viewport().gui_get_hovered_control() != _sub_view_container: 
		return false
	return true

#returns the tile currently hovered by the cursor
func _get_hovered_tile() -> Vector2i:
	var subview_pos = _sub_viewport.get_mouse_position()
	var world_pos = (subview_pos / _camera.zoom) + _camera.position
	var tile_pos = _tile_grid.local_to_map(_tile_grid.to_local(world_pos))
	return tile_pos

#checks if a position is inside the map grid
func _is_in_bounds(pos: Vector2i) -> bool: 
	return (pos.x < _get_width() and pos.x >= 0 and pos.y < _get_height() and pos.y >= 0)

#returns the average color of a texture
func _get_texture_average_color(tex: Texture2D) -> Color:
	var img: Image = tex.get_image()
	var r = 0.0
	var g = 0.0
	var b = 0.0
	var a = 0.0
	var count = float(img.get_width() * img.get_height())
	for x in img.get_width():
		for y in img.get_height(): 
			var c = img.get_pixel(x, y)
			r += c.r
			g += c.g
			b += c.b
			a += c.a
	return Color(r / count, g / count, b / count, a / count)

#checks if outer dictionary contains all the keys of inner 
#and if the values for those keys match
func _has_all_keys_and_values(inner: Dictionary, outer: Dictionary) -> bool: 
	if outer.has_all(inner.keys()):
		for key in inner.keys(): 
			if outer[key] is Array: 
				if !outer[key].has(inner[key]):
					return false
			elif inner[key] != outer[key]:
				return false
		return true
	else:
		return false


##GETTERS / SETTERS
func _get_width() -> int:
	return _attribute_grid.width
	
func _get_height() -> int:
	return _attribute_grid.height
	
func get_attribute_grid() -> Array2D:
	return _attribute_grid

#will return an approximation texture of the map
#the result texture will have the same dimensions as the map
#each pixel on the texture will be the average color of the matching
#tile texture on the map
func get_map_as_thumbnail() -> Texture2D: 
	var width = _attribute_grid.width
	var height = _attribute_grid.height
	var thumbnail_img : Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	for grid_x in width:
		for grid_y in height:
			var tile_attributes = _attribute_grid.getItem(grid_x, grid_y)
			if tile_attributes.has(_tile_texture_id):
				var tile_tex: Texture2D = tile_attributes[_tile_texture_id]
				var tile_tex_avr_color = _get_texture_average_color(tile_tex)
				thumbnail_img.set_pixel(grid_x, grid_y, tile_tex_avr_color)
	return ImageTexture.create_from_image(thumbnail_img)











#
