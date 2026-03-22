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
@onready var _map_name_label: Label = $HBoxContainer/SubViewControl/MapName

enum InputState {
	INTERACT,
	ERASE,
	PAINT
}


##GENERAL DATA
var layers: Array[MapLayer]
var _map_name: String = "Unnamed map"

##PAINT LIBRARY DATA
#maps each library name to an array of Dictionary[String, Variant]
#Maps library names to an array of it items
#Arrays are arrays of dictionaries 
#each dictionary has its librarys defined overwrite and addable key value pairs
var _lib_items_data: Dictionary[String, Array] = {}
#Maps libraries with their names
var _paint_libraries: Dictionary[String, PaintLibrary]


##ATTRIBUTE DATA
#Tells the painter which attribute in tile attirbute list is used 
#the unique identifier for a tile type



var _width: int
var _height: int


##Variables used for painting 
var _active_layer: int = 0
#current input state, decides what clicking on tiles does
var _input_state = InputState.INTERACT
#tilemap layer painting stuff
const _PAINT_TILE_ATLAS_CORD: Vector2i = Vector2i(0,0)
#refers to the id of the source texture being used to paint the tiles
var _paint_tex: Texture2D = null
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
func init_painter(width: int, height: int) -> void: 
	_width = width
	_height = height
	_background_grid.gen_map(width, height)

func add_layer(tile_texture_id: Variant, tile_id: Variant) -> int: 
	layers.append(MapLayer.new(_width, _height, tile_texture_id, tile_id))
	var layer_tile_map = layers.back().get_tile_map_layer()
	_sub_viewport.add_child(layer_tile_map)
	_sub_viewport.move_child(layer_tile_map, layers.size() - 1)
	return layers.size() - 1

##reciever functions for library button presses
#add function will change the add attributes 
#overwrite will change the overwrite attirbutes
#these two attirbute lists are responsible for painting tiles on the grid 
func on_lib_item_pressed(addable: Dictionary[String, Variant], 
					  overwrite: Dictionary[String, Variant], highlight: bool, layer_id: int) -> void: 
	_active_layer = layer_id
	if layers.size() <= layer_id:
		print("lib item calls for nonexistent layer: " + str(layer_id))
		return
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
	var tex_id = layers[_active_layer].get_tile_texture_id()
	if overwrite.has(tex_id): 
		_paint_tex = overwrite[tex_id]
	else: 
		_paint_tex = null
	#highlighting 
	#clear previous highlight by regenerating the background grid
	#if there was highlighting before
	if old_highlight_state:
		_background_grid.regenerate(_width, _height)
	if highlight:
		#highlight freshly
		_highlight_with_attributes(addable, overwrite, layer_id)

func sync_lib_item(lib_name: String, item_id: String, item_id_value: Variant, layer_id: int) -> void: 
	if _lib_items_data.has(lib_name): 
		var lib_items = _lib_items_data[lib_name]
		var item_indx = lib_items.find_custom(
			(func(item): return item is Dictionary and item.has(item_id) and item[item_id] == item_id_value)) 
		layers[layer_id].sync_attributes(lib_items[item_indx], item_id, item_id_value)

func remove_lib_item(lib_name: String, item_id: String, item_id_value: Variant, layer_id: int) -> void:
	if _lib_items_data.has(lib_name): 
		var lib_items = _lib_items_data[lib_name]
		for item in lib_items:
			if item is Dictionary:
				if item.has(item_id) and item[item_id] == item_id_value: 
					#remove the matching tiles from the map
					layers[layer_id].remove_attributes(item, item_id, item_id_value)
					#remove the item from library
					lib_items.erase(item)
					_paint_libraries[lib_name].initialize_lib_items(lib_items)


##State incrementing / decremeneting functions
##A lot of these are called from outside the class
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
	if _find_dictionary_item(_lib_items_data[lib_name], item_id, data[item_id]) == -1:
		_lib_items_data[lib_name].append(data)
		_paint_libraries[lib_name].initialize_lib_items(_lib_items_data[lib_name])

#adds a new library to the map painter (look up PaintLibrary)
func add_library(lib_name: String, overwrite_data: Dictionary[String, Variant], 
				addable_data: Dictionary[String, Variant], preview_texture_id: String, name_id: String, layer_id: int,
				new_button: bool = false, highlight: bool = false, lib_new_button_callback: Callable = Callable()) -> void: 
	var _tile_library: PaintLibrary = preload("res://editor/editors/map_editor_refactor/user_interfaces/paint_library/paint_library.tscn").instantiate()
	_content_vbox.add_child(_tile_library)
	##CAN USE AFTER ADDED TO TREE
	#init the library
	_tile_library.init(lib_name, preview_texture_id, name_id, 
						overwrite_data, addable_data, layer_id, new_button, highlight, lib_new_button_callback)
	#add the library to the library map, so we can refrence it later
	_paint_libraries[lib_name] = (_tile_library)
	#connect library signals
	_tile_library.lib_item_pressed.connect(on_lib_item_pressed)
	_tile_library.lib_item_removed.connect(remove_lib_item)
	_tile_library.lib_item_added.connect(add_new_lib_item)
	#as map painter contains the items for the libs, 
	#set the array of items of this lib to an empty one (basically init it) 
	_lib_items_data[lib_name] = []

#function to remove a library
func remove_library(lib_name: String) -> void: 
	var item_id = _paint_libraries[lib_name].get_item_id()
	var layer_id = _paint_libraries[lib_name].get_layer_id()
	#remove every lib_item
	for lib_item in _lib_items_data[lib_name]:
		var item_id_value = lib_item[item_id]
		remove_lib_item(lib_name, item_id, item_id_value, layer_id)
	#remove the lib
	_content_vbox.remove_child(_paint_libraries[lib_name])
	_paint_libraries.erase(lib_name)

#reloads a library completely from external data
#item in: 
#only in data -> add
#only in library -> remove_lib_item()
#in both -> sync_attributes()
func sync_library(data: Array, lib_name: String) -> void:
	#if lib doesnt exist we cant do anything
	if !_paint_libraries.has(lib_name):
		return
	var item_id = _paint_libraries[lib_name].get_item_id()
	var layer_id =_paint_libraries[lib_name].get_layer_id()
	
	var to_be_removed: Array = []
	for item_indx in _lib_items_data[lib_name].size(): 
		var item = _lib_items_data[lib_name][item_indx]
		var data_item_indx = _find_dictionary_item(data, item_id, item[item_id])
		if data_item_indx == -1:
			to_be_removed.append(item)
		else: 
			layers[layer_id].sync_attributes(data[data_item_indx], item_id, item[item_id])
			_lib_items_data[lib_name][item_indx] = data[data_item_indx]
			#sync_lib_item(lib_name, item_id, item[item_id], layer_id)
	for item in to_be_removed: 
		remove_lib_item(lib_name, item_id, item[item_id], layer_id)
	#set the lib data to new! 
	#we will add every item to the library
	#keep in mind that "add_new_lib_item" does nothing if the item already exists in the lib
	for item in data:
		add_new_lib_item(item, lib_name)
	for layer in layers:
		layer.update_tile_map()
	_update_libraries()

func reset(width, height) -> void: 
	for layer in layers:
		layer.reset_grids(width, height)
	_width = width
	_height = height
	_background_grid.regenerate(width, height)

func resize(width, height) -> void: 
	for layer in layers:
		layer.update_grids(width, height)
	_width = width
	_height = height
	_background_grid.regenerate(width, height)

#reloads a layer absed on an attribute grid
func reload_layer(attribute_grid: Array2D, layer_id: int) -> void: 
	if layer_id >= layers.size():
		print("trying to reload a nonexistent layer")
		return
	layers[layer_id].reset_from_data(attribute_grid)

func get_layer(layer_id: int) -> Array2D: 
	if layer_id >= layers.size():
		print("trying to get a nonexistent layer")
		return
	return layers[layer_id].get_attribute_grid()


##IMPORT / EXPORT
##AND STATE UPDATING FUNCTIONS (for loading and reloading the state of the map painter) 

#imports a map from a "MapPainterRes" resource
#The resource has to be exported from the same type of MapPainter
func import(path: String) -> void:
	var res: MapPainterRes = ResourceLoader.load(path) as MapPainterRes
	import_from_resource(res)

func import_from_resource(res: MapPainterRes) -> void: 
	_width = res.get_width()
	_height = res.get_height()
	##setup layers
	#attribute_grids should match order with layers
	var attribute_grids = res.get_attribute_grids()
	for layer_id in layers.size():
		if(attribute_grids.size() <= layer_id):
			print("Attribute grid array doesn't match layers in map painter import")
			return
		layers[layer_id].set_attribute_grid(attribute_grids[layer_id])
		layers[layer_id].update_tile_map()
	
	##libs and background
	_lib_items_data = res.get_lib_items()
	_update_libraries()
	
	_background_grid.regenerate(_width, _height)

	##map name
	set_map_name(res.get_map_name())

#exports the map as a resource "MapPainterRes"
#this export will be only readable by the same type of MapPainter that exported it
func export(path: String) -> void: 
	var res: MapPainterRes = MapPainterRes.new()
	var attribute_grids: Array[Array2D]
	for layer in layers:
		attribute_grids.append(layer.get_attribute_grid())
	res.init(_width, _height, attribute_grids, _lib_items_data, _map_name)
	var err = ResourceSaver.save(res, path)
	if err != OK:
		print("error", err)

func export_as_resource() -> MapPainterRes: 
	var res: MapPainterRes = MapPainterRes.new()
	var attribute_grids: Array[Array2D]
	for layer in layers:
		attribute_grids.append(layer.get_attribute_grid())
	res.init(_width, _height, attribute_grids, _lib_items_data, _map_name)
	return res

##DYNAMIC flow functions
func set_to_default_state() -> void: 
	_change_state(InputState.INTERACT)

#simple function to change current input state
func _change_state(new_state: InputState) -> void:
	_input_state = new_state
	if new_state != InputState.PAINT && _highlight:
		_highlight = false
		_background_grid.regenerate(_width, _height)


#callback from settings popup (called from popup manager) 
#updates the state of the painter, calls updateGrids() 
func update_settings(settings: Dictionary[String, Variant]) -> void:
	if settings.has("width"): 
		_width = settings["width"]
	if settings.has("height"):
		_height = settings["height"]
	if settings.has("map_name"):
		_map_name = settings["map_name"]
		_map_name_label.text = _map_name
	for layer in layers:
		layer.update_grids(_width, _height)
	_background_grid.regenerate(_width, _height)

#update all libraries with _lib_items_data
func _update_libraries() -> void: 
	for lib_name in _paint_libraries.keys(): 
		_paint_libraries[lib_name].initialize_lib_items(_lib_items_data[lib_name])

#highlights every tile in background grid 
#whose attribute lists have the equal keys and values
func _highlight_with_attributes(addable: Dictionary[String, Variant], 
								overwrite: Dictionary[String, Variant], layer_id: int) -> void: 
	if (layer_id >= layers.size()): 
		print("trying to highlight with nonexistent layer " + str(layer_id))
	var attribute_grid = layers[layer_id].get_attribute_grid()
	for x in attribute_grid.width:
		for y in attribute_grid.height: 
			if (_has_all_keys_and_values(overwrite, attribute_grid.getItem(x, y)) and 
				_has_all_keys_and_values(addable, attribute_grid.getItem(x, y))):
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
					layers[_active_layer].erase_tile(hovered_tile)
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
					layers[_active_layer].erase_tile(hovered_tile)
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
				var tile_data: Dictionary[String, Variant] = {}
				for layer in layers:
					var layer_tile_data = layer.get_attribute_grid().getItem(hovered_tile.x, hovered_tile.y)
					tile_data.merge(layer_tile_data)
				_tile_descriptor.update(tile_data)
					

#will be calld if PAINT state, 
#will set the attributes based on overwrite list and add list
#Will set the 
func _paint_tile(hovered_tile: Vector2i) -> void:
	#paint value will be -1 if we are not currently paiting tile appearances
	#meaning that we are currently only painting attributes
	if _paint_tex != null:
		layers[_active_layer].paint_tile(hovered_tile, _paint_tex)
	if _highlight:
		_background_grid.set_cell(hovered_tile, _paint_highlight_value, _PAINT_TILE_ATLAS_CORD)
	for key in _overwrite_attribute_list: 
		layers[_active_layer].overwrite_tile_attribute(hovered_tile, key, _overwrite_attribute_list[key])
	for key in _addable_attribute_list: 
		layers[_active_layer].add_tile_attribute(hovered_tile, key, _addable_attribute_list[key])


##POPUPS
func open_settings_popup() -> void: 
	var settings_popup: SettingsPopup = preload("res://editor/editors/map_editor_refactor/popup_windows/settings_popup.tscn").instantiate()
	settings_popup.add_to_tree()
	settings_popup.init(_generate_settigns_dict())
	settings_popup.saved.connect(update_settings)

#popup manager callback, returns true if map painter is active
func is_active() -> bool: 
	return is_visible_in_tree() and visible


##utility functions: 
#checks if a library already has an item with the specific id 
func _find_dictionary_item(data: Array, item_id: String, id_value: Variant) -> int: 
	var count = 0
	for item in data:
		if item is Dictionary:
			if item.has(item_id) and item[item_id] == id_value:
				return count
		count +=1
	return -1

func _generate_settigns_dict() -> Dictionary[String, Variant]:
	return {"width": _width, "height": _height, "map_name": _map_name}
#checks if the cursor is not in the paint area 
func _mouse_on_map() -> bool: 
	if get_viewport().gui_get_hovered_control() != _sub_view_container: 
		return false
	return true

#returns the tile currently hovered by the cursor
func _get_hovered_tile() -> Vector2i:
	var subview_pos = _sub_viewport.get_mouse_position()
	var world_pos = (subview_pos / _camera.zoom) + _camera.position
	var tile_pos = _background_grid.local_to_map(_background_grid.to_local(world_pos))
	return tile_pos

#checks if a position is inside the map grid
func _is_in_bounds(pos: Vector2i) -> bool: 
	return (pos.x < _width and pos.x >= 0 and pos.y < _height and pos.y >= 0)

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

func set_active_layer(layer_id: int) -> void: 
	if layer_id < layers.size():
		_active_layer = layer_id

##GETTERS / SETTERS
#TODO: maybe merge layer attributegrids
func get_attribute_grid() -> Array2D:
	return layers[_active_layer].get_attribute_grid()

#will return an approximation texture of the map
#the result texture will have the same dimensions as the map
#each pixel on the texture will be the average color of the matching
#tile texture on the map
func get_map_as_thumbnail() -> Texture2D: 
	var thumbnail_img : Image = Image.create(_width, _height, false, Image.FORMAT_RGBA8)
	var attribute_grid = layers[_active_layer].get_attribute_grid()
	var tile_tex_id = layers[_active_layer].get_tile_texture_id()
	for grid_x in _width:
		for grid_y in _height:
			var tile_attributes = attribute_grid.getItem(grid_x, grid_y)
			if tile_attributes.has(tile_tex_id):
				var tile_tex: Texture2D = tile_attributes[tile_tex_id]
				var tile_tex_avr_color = _get_texture_average_color(tile_tex)
				thumbnail_img.set_pixel(grid_x, grid_y, tile_tex_avr_color)
	return ImageTexture.create_from_image(thumbnail_img)


func get_library_names() -> Array: 
	return _paint_libraries.keys()

func set_map_name(map_name: String) -> void: 
	_map_name = map_name
	_map_name_label.text = map_name
	print("map name set to: " + map_name)








#
