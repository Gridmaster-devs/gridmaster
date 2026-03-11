class_name GameEditor
extends Control

var editor_main : EditorMain
var game_resource : GameDefinitionResource
@onready var game_name_line : LineEdit = $"PanelContainer/VBoxContainer/HBoxContainer/Game name"
@onready var save_game_button : Button = $"PanelContainer/VBoxContainer/HBoxContainer/Save game"
@onready var load_game_button : Button = $"PanelContainer/VBoxContainer/HBoxContainer/Load game"
@onready var _contents_container: VBoxContainer = $PanelContainer/VBoxContainer
@onready var ftm : FileTransferManager = $Dialogs/FileTransferManager


var _base_layer_id: int
var _unit_layer_id: int

##painting
var _unit_painter: MapPainter = null

# links the editor_main object
func link_editor_main(editor_main_p : EditorMain):
	editor_main = editor_main_p


# called by pressing the save button
func save_to_file():
	var units = editor_main.get_units()
	var map = editor_main.getMap()
	
	var game_name = get_game_name()
	if game_name == "": 
		game_name = "game"
	game_resource = GameDefinitionResource.new()
	game_resource.save_name(game_name)
	game_resource.save_units(units)
	game_resource.saveMap(map)
	
	ftm.download_data(game_resource, game_name + ".tres", "*.tres", true)


func load_from_file() -> void:
	ftm.upload_data("*.tres", true)

# called by load_from_file
func load_from_resource(resource : GameDefinitionResource):
	set_game_name(resource.game_name)
	editor_main.set_units(resource.load_units())
	editor_main.setMap(resource.loadMap())


func get_game_name() -> String:
	return game_name_line.text
	
	
func set_game_name(name_p : String):
	game_name_line.text = name_p
	
func _create_unit_painter() -> MapPainter: 
	var painter_scene = preload("res://editor/editors/map_editor_refactor/user_interfaces/map_painter.tscn")
	var _painter: MapPainter = painter_scene.instantiate()
	_contents_container.add_child(_painter)
	
	##HAS TO BE CALLED AFTER ADDED TO SCENE 
	_painter.init_painter(10, 10)
	_base_layer_id = _painter.add_layer(MapAttributes.STRATEGIC_TEXTURE_ID, MapAttributes.STRATEGIC_TILE_ID)
	_unit_layer_id = _painter.add_layer(MapAttributes.UNIT_TEXTURE_ID, MapAttributes.UNIT_TILE_ID)
	_painter.add_library(MapAttributes.UNIT_UNIT_LIB_NAME, MapAttributes.UNIT_UNIT_LIB_OVERWRITE, 
								MapAttributes.UNIT_UNIT_LIB_ADD, 
								MapAttributes.UNIT_UNIT_LIB_TEXTURE_ID,
								MapAttributes.UNIT_UNIT_LIB_ITEM_ID, _unit_layer_id, true)
	return _painter


func _reload() -> void:
	#reload the units
	_sync_unit_lib()
	#reload the map
	_sync_map()


func _sync_map() -> void:
	var attribute_grid = editor_main.getMap().get_strategic_map().get_attribute_grids()[0]
	_unit_painter.reload_layer(attribute_grid, _base_layer_id)

func _sync_unit_lib() -> void: 
	var units = editor_main.get_units()
	var data: Array = []
	for unit in units: 
		var unit_name: String = unit.get_attribute("name").attribute_value
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color.from_rgba8(0, 0, 0, 0))  
		for x in range(64): 
			for y in range(64):
				if x > 16 and x <= 48 and y > 16 and y <= 48: 
					img.set_pixel(x, y, Color.from_rgba8(255, 0, 0, 255))
		var unit_texture: Texture2D = ImageTexture.create_from_image(img)
		var datapoint: Dictionary[String, Variant] = {
			MapAttributes.UNIT_UNIT_LIB_ITEM_ID: unit_name,
		 	MapAttributes.UNIT_UNIT_LIB_TEXTURE_ID: unit_texture}
		data.append(datapoint)
	_unit_painter.sync_library(data, MapAttributes.UNIT_UNIT_LIB_NAME)

func _on_visibibility_changed() -> void:
	if visible: 
		_reload()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ftm.resource_uploaded.connect(load_from_resource)
	
	save_game_button.button_up.connect(save_to_file)
	load_game_button.button_up.connect(load_from_file)
	visibility_changed.connect(_on_visibibility_changed)
	_unit_painter = _create_unit_painter()
















#
