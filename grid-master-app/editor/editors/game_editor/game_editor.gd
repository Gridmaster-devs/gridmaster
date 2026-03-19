class_name GameEditor
extends Control

var editor_main : EditorMain
var game_resource : GameDefinitionResource
@onready var game_name_line : LineEdit = $"PanelContainer/VBoxContainer/Game name"
@onready var save_game_button : Button = $"PanelContainer/VBoxContainer/HBoxContainer/Save game"
@onready var load_game_button : Button = $"PanelContainer/VBoxContainer/HBoxContainer/Load game"
@onready var _tab_container: TabContainer = $PanelContainer/VBoxContainer/TabContainer
@onready var ftm : FileTransferManager = $Dialogs/FileTransferManager

@onready var _teams_container: GridContainer = $PanelContainer/VBoxContainer/TabContainer/Teams/TopVBox/ScrollContainer/ContentsVBox/GridContainer
@onready var _new_team_button: Button = $PanelContainer/VBoxContainer/TabContainer/Teams/TopVBox/ScrollContainer/ContentsVBox/NewTeamButton
@onready var _save_button: Button = $PanelContainer/VBoxContainer/TabContainer/Teams/TopVBox/ScrollContainer/ContentsVBox/SaveTeamsButton


#teams
var _team_uis: Array[TeamUi] = []
var _teams: Array[GameTeam] = []

#units
@export var unit_outline_thickeness: int = 3

##painting
var _unit_painter: MapPainter = null
var _base_layer_id: int
var _unit_layer_id: int


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
	game_resource.save_unit_layer(_unit_painter.get_layer(_unit_layer_id))
	game_resource.save_team_uis(_get_team_uis_res())
	ftm.download_data(game_resource, game_name + ".tres", "*.tres", true)

func _get_team_uis_res() -> Array[TeamUiRes]: 
	var out: Array[TeamUiRes] = []
	for team_ui in _team_uis: 
		out.append(team_ui.export())
	return out

func load_from_file() -> void:
	ftm.upload_data("*.tres", true)

# called by load_from_file
func load_from_resource(resource : GameDefinitionResource):
	set_game_name(resource.game_name)
	editor_main.set_units(resource.load_units())
	editor_main.setMap(resource.loadMap())
	_unit_painter.reload_layer(resource.load_unit_layer(), _unit_layer_id)
	#teams
	_clear_teams()
	for team_ui_res in resource.load_team_uis():
		_add_new_team_ui().import(team_ui_res)
	_on_teams_save()
	_reload()


func get_game_name() -> String:
	return game_name_line.text

func set_game_name(name_p : String):
	game_name_line.text = name_p
	
func _create_unit_painter() -> MapPainter: 
	var painter_scene = preload("res://editor/editors/map_editor_refactor/user_interfaces/map_painter.tscn")
	var _painter: MapPainter = painter_scene.instantiate()
	_tab_container.add_child(_painter)
	_tab_container.set_tab_title(1, "Map")
	
	##HAS TO BE CALLED AFTER ADDED TO SCENE 
	_painter.init_painter(10, 10)
	_base_layer_id = _painter.add_layer(MapAttributes.STRATEGIC_TEXTURE_ID, MapAttributes.STRATEGIC_TILE_ID)
	_unit_layer_id = _painter.add_layer(MapAttributes.UNIT_TEXTURE_ID, MapAttributes.UNIT_TILE_ID)
	return _painter

func _reload() -> void:
	#sync team uis
	_sync_team_uis()
	#reload the units
	_sync_team_libraries()
	#reload the map
	_sync_map()

func _sync_map() -> void:
	var attribute_grid = editor_main.getMap().get_strategic_map().get_attribute_grids()[0]
	_unit_painter.reload_layer(attribute_grid, _base_layer_id)
	_unit_painter.resize(attribute_grid.width, attribute_grid.height)

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
	
	#teams ui
	_new_team_button.pressed.connect(_add_new_team_ui)
	_save_button.pressed.connect(_on_teams_save)

func _add_new_team_ui() -> TeamUi: 
	var team_ui: TeamUi = preload("res://editor/editors/game_editor/team_ui.tscn").instantiate()
	_teams_container.add_child(team_ui)
	team_ui.init_units(_get_team_names())
	_team_uis.append(team_ui)
	return team_ui

func _on_teams_save() -> void: 
	_teams.clear()
	var count = 0
	for team_ui in _team_uis: 
		var team_name = team_ui.get_team_name()
		var team_color = team_ui.get_team_color()
		var team_units = team_ui.get_team_units()
		var team_id = count
		_teams.append(GameTeam.new(team_name, team_color, team_id, team_units))
		count += 1
	_sync_team_libraries()

func _sync_team_uis() -> void: 
	var arr: Array = []
	for unit in editor_main.get_units():
		var unit_name: String = unit.get_attribute("name").attribute_value
		arr.append(unit_name)
	for team_ui in _team_uis:
		team_ui.sync_units(arr)

func _sync_team_libraries() -> void: 
	var lib_names = _unit_painter.get_library_names()
	var new_lib_names: Array = []
	for team in _teams:
		var lib_name = team.get_name()
		if lib_names.has(lib_name):
			_unit_painter.sync_library(_generate_team_lib_data(team), lib_name)
		else: 
			_unit_painter.add_library(lib_name, MapAttributes.UNIT_UNIT_LIB_OVERWRITE, MapAttributes.UNIT_UNIT_LIB_ADD,
									MapAttributes.UNIT_UNIT_LIB_TEXTURE_ID,
									MapAttributes.UNIT_UNIT_LIB_ITEM_ID, _unit_layer_id, false, true)
			_unit_painter.sync_library(_generate_team_lib_data(team), lib_name)
		new_lib_names.append(lib_name)
	#remove libs that are in the painter but not in teams
	for lib_name in lib_names: 
		if !new_lib_names.has(lib_name):
			_unit_painter.remove_library(lib_name)

func _clear_teams() -> void: 
	_teams.clear()
	for team_ui in _team_uis: 
		_teams_container.remove_child(team_ui)
	_team_uis.clear()

##UTIL
func _generate_team_lib_data(team: GameTeam) -> Array: 
	var data: Array = []
	var team_units = team.get_units()
	for unit in editor_main.get_units():
		var unit_name: String = unit.get_attribute("name").attribute_value
		if !team_units.has(unit_name):
			continue
		var unit_texture: Texture2D = _generate_colored_unit_texture(team.get_color(), _generate_default_unit_texture())
		var datapoint: Dictionary[String, Variant] = {
			MapAttributes.UNIT_UNIT_LIB_ITEM_ID: unit_name,
		 	MapAttributes.UNIT_UNIT_LIB_TEXTURE_ID: unit_texture,
			MapAttributes.UNIT_TEAM_ID: team.get_name()}
		data.append(datapoint)
	return data

func _get_team_names() -> Array:
	var data: Array = []
	for unit in editor_main.get_units():
		var unit_name: String = unit.get_attribute("name").attribute_value
		data.append(unit_name)
	return data

func _generate_colored_unit_texture(color: Color, unit: Texture2D, alpha_threshold: float = 0.5) -> Texture2D:
	var img = unit.get_image().duplicate(true)
	var width = img.get_width()
	var height = img.get_height()
	
	# duplicate the original for neighbor checks
	var original = img.duplicate(true)
	
	for x in range(width):
		for y in range(height):
			var p = original.get_pixel(x, y)
			if p.a < alpha_threshold and _has_opaque_neighbor(original, Vector2i(x, y), alpha_threshold):
				img.set_pixel(x, y, color)
	
	return ImageTexture.create_from_image(img)


func _has_opaque_neighbor(img: Image, pos: Vector2i, alpha_threshold: float) -> bool:
	var width = img.get_width()
	var height = img.get_height()
	
	for dx in range(-unit_outline_thickeness, unit_outline_thickeness + 1):
		for dy in range(-unit_outline_thickeness, unit_outline_thickeness + 1):
			if dx == 0 and dy == 0:
				continue  # skip the center pixel
			var nx = pos.x + dx
			var ny = pos.y + dy
			if nx < 0 or nx >= width or ny < 0 or ny >= height:
				continue
			var np = img.get_pixel(nx, ny)
			if np.a >= alpha_threshold:
				return true
	return false


func _generate_default_unit_texture() -> Texture2D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color.from_rgba8(0, 0, 0, 0))  
	for x in range(64): 
		for y in range(64):
			if x > 16 and x <= 48 and y > 16 and y <= 48: 
				img.set_pixel(x, y, Color.from_rgba8(255, 0, 0, 255))
	return ImageTexture.create_from_image(img)

#
