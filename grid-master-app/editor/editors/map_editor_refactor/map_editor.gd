extends Node
class_name MapEditor


enum MapMode {
	STRATEGIC,
	TACTICAL
}


@onready var _main_container: VBoxContainer = $MainContainer
@onready var _map_mode_button: Button = $MainContainer/TopBar/TopVBox/ScrollContainer/ContentsVBox/HBoxContainer/MapMode
@onready var _save_button: Button = $MainContainer/TopBar/TopVBox/ScrollContainer/ContentsVBox/HBoxContainer/Save
@onready var _load_button: Button = $MainContainer/TopBar/TopVBox/ScrollContainer/ContentsVBox/HBoxContainer/Load
@onready var _ftm: FileTransferManager = $Dialogs/FileTransferManager


var _tactical_painter: MapPainter
var _strategic_painter: MapPainter
var _map_mode: MapMode
var _tactical_maps: Dictionary[String, MapPainterRes]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_tactical_painter = create_tactical_painter()
	_strategic_painter = create_strategic_painter()
	_tactical_painter.visible = false
	_map_mode = MapMode.STRATEGIC
	_map_mode_button.pressed.connect(_change_map_mode)
	_save_button.pressed.connect(_open_save_popup)
	_load_button.pressed.connect(_load_map)
	_ftm.resource_uploaded.connect(load_map_from_resource)

func _init() -> void: 
	pass

func create_tactical_painter() -> MapPainter: 
	var painter_scene = preload("res://editor/editors/map_editor_refactor/user_interfaces/map_painter.tscn")
	var _painter: MapPainter = painter_scene.instantiate()
	_main_container.add_child(_painter)
	
	##HAS TO BE CALLED AFTER ADDED TO SCENE 
	_painter.init_painter(MapAttributes.TACTICAL_TEXTURE_ID, MapAttributes.TACTICAL_TILE_ID, 10, 10)
	_painter.add_library(MapAttributes.TACTICAL_TILE_LIB_NAME, MapAttributes.TACTICAL_TILE_LIB_OVERWRITE, 
								MapAttributes.TACTICAL_TILE_LIB_ADD, 
								MapAttributes.TACTICAL_TILE_LIB_TEXTURE_ID, 
								MapAttributes.TACTICAL_TILE_LIB_ITEM_ID)
	return _painter

#creates the strategic painter for the editor
#this is the outer map, will have two libraries (one for tiles and one for tactical maps) 
func create_strategic_painter() -> MapPainter: 
	var painter_scene = preload("res://editor/editors/map_editor_refactor/user_interfaces/map_painter.tscn")
	var _painter: MapPainter = painter_scene.instantiate()
	_main_container.add_child(_painter)
	
	##HAS TO BE CALLED AFTER ADDED TO SCENE 
	_painter.init_painter(MapAttributes.STRATEGIC_TEXTURE_ID, MapAttributes.STRATEGIC_TILE_ID, 10, 10)
	_painter.add_library(MapAttributes.STRATEGIC_TILE_LIB_NAME, MapAttributes.STRATEGIC_TILE_LIB_OVERWRITE, 
								MapAttributes.STRATEGIC_TILE_LIB_ADD, 
								MapAttributes.STRATEGIC_TILE_LIB_TEXTURE_ID, 
								MapAttributes.STRATEGIC_TILE_LIB_ITEM_ID)
	_painter.add_library(MapAttributes.STRATEGIC_TACTICAL_LIB_NAME, MapAttributes.STRATEGIC_TACTICAL_LIB_OVERWRITE,
								MapAttributes.STRATEGIC_TACTICAL_LIB_ADD, 
								MapAttributes.STRATEGIC_TACTICAL_LIB_TEXTURE_ID, 
								MapAttributes.STRATEGIC_TACTICAL_LIB_ITEM_ID, 
								true, _change_map_mode)
	return _painter

#changes the painter active
func _change_map_mode() -> void: 
	if _map_mode == MapMode.STRATEGIC:
		_map_mode = MapMode.TACTICAL
		_map_mode_button.text = "TACTICAL"
		_tactical_painter.visible = true
		_strategic_painter.visible = false
	else:
		_map_mode = MapMode.STRATEGIC
		_map_mode_button.text = "STRATEGIC"
		_tactical_painter.visible = false
		_strategic_painter.visible = true



#opens the save popup
#which will prompt a name to save with
func _open_save_popup() -> void: 
	var save_popup: SaveNamePopup = preload("res://editor/editors/map_editor_refactor/popup_windows/save_name_popup.tscn").instantiate()
	save_popup.save_confirmed.connect(_on_save_popup_confirmed)
	get_tree().call_group("map_editor_popup_manager", "add_new_popup", 
							save_popup, save_popup.get_popup_name())
	

#when save_tactical_popup is finished with a named tactical map
func _on_save_popup_confirmed(map_name: String) -> void: 
	if _map_mode == MapMode.STRATEGIC:
		_on_strategic_map_saved(map_name)
	else: 
		_on_tactical_map_saved(map_name)
	
func _on_strategic_map_saved(map_name: String) -> void: 
	_save_map(map_name)
	
func _on_tactical_map_saved(map_name: String) -> void:
	_tactical_maps[map_name] = _tactical_painter.export_as_resource()
	var thumbnail = _tactical_painter.get_map_as_thumbnail()
	_tactical_painter.reset_grids(10, 10)
	var data: Dictionary[String, Variant] = {
			MapAttributes.STRATEGIC_TACTICAL_LIB_ITEM_ID: String(), 
			MapAttributes.STRATEGIC_TACTICAL_LIB_TEXTURE_ID: Texture2D.new()}
	data[MapAttributes.STRATEGIC_TACTICAL_LIB_TEXTURE_ID] = thumbnail
	data[MapAttributes.STRATEGIC_TACTICAL_LIB_ITEM_ID] = map_name
	_strategic_painter.add_new_lib_item(data, MapAttributes.STRATEGIC_TACTICAL_LIB_NAME)
	_change_map_mode()

#required function for popup manager
#it will call this and check if it is active
func is_active() -> bool:
	return self.visible

#saves the map by calling fmt
func _save_map(map_name: String):
	if map_name == "":
		map_name = "game_map"
	var res: MapResource = MapResource.new()
	res.init(_strategic_painter.export_as_resource(), _tactical_maps)
	_ftm.download_data(res, map_name + ".tres", "*.tres", true)

#loads the map by calling fmt
func _load_map() -> void:
	_ftm.upload_data("*.tres", true)

#function that is conected to "resource uploaded" signal in fmt
func load_map_from_resource(res : Resource) -> void:
	if res is not MapResource:
		print("Resource was not a map resource on load")
		return
	_tactical_maps = res.get_tactical_maps()
	_strategic_painter.import_from_resource(res.get_strategic_map())
	if !_tactical_maps.is_empty():
		var first_key = _tactical_maps.keys()[0]
		_tactical_painter.import_from_resource(_tactical_maps[first_key])
		_tactical_painter.reset_grids(10, 10)

#returns the map as a resource while preserving data
func get_map_as_resource() -> MapResource: 
	var res: MapResource = MapResource.new()
	res.init(_strategic_painter.export_as_resource(), _tactical_maps)
	return res

###
