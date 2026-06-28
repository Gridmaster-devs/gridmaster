class_name GameEditor
extends Control

var editor_main : EditorMain
var game_resource : GameDefinitionResource
@onready var game_name_line : LineEdit = $"PanelContainer/VBoxContainer/Game name"
@onready var save_game_button : Button = $"PanelContainer/VBoxContainer/HBoxContainer/Save game"
@onready var load_game_button : Button = $"PanelContainer/VBoxContainer/HBoxContainer/Load game"
@onready var _tab_container: TabContainer = $PanelContainer/VBoxContainer/TabContainer
@onready var ftm : FileTransferManager = $Dialogs/FileTransferManager

@onready var _unit_painter: MapPainter = $PanelContainer/VBoxContainer/TabContainer/Map
@onready var _game_rules: GameRules = $PanelContainer/VBoxContainer/TabContainer/GameRules

@onready var _teams_container: GridContainer = $PanelContainer/VBoxContainer/TabContainer/Teams/TopVBox/ScrollContainer/ContentsVBox/TeamsVbox/GridContainer
@onready var _new_team_button: Button = $PanelContainer/VBoxContainer/TabContainer/Teams/TopVBox/ScrollContainer/ContentsVBox/TeamsVbox/NewTeamButton
@onready var _new_player_button: Button = $PanelContainer/VBoxContainer/TabContainer/Teams/TopVBox/ScrollContainer/ContentsVBox/PlayersVbox/NewPlayerButton
@onready var _players_container: GridContainer = $PanelContainer/VBoxContainer/TabContainer/Teams/TopVBox/ScrollContainer/ContentsVBox/PlayersVbox/GridContainer

#constants
const TEAMS_TAB_ID = 0
const GAME_RULES_TAB_ID = 1
const MAP_TAB_ID = 2

#teams / players
var _team_uis: Array[TeamUi] = []
var _teams: Array[GameTeam] = []
var _player_uis: Array[PlayerUi] = []
var _players: Array[GamePlayer] = []

#units
@export var unit_outline_thickeness: int = 3

#painting
var _base_layer_id: int
var _unit_layer_id: int


##State functions
func _ready() -> void:
	ftm.resource_uploaded.connect(load_from_resource)
	save_game_button.button_up.connect(save_to_file)
	load_game_button.button_up.connect(load_from_file)
	visibility_changed.connect(_on_visibibility_changed)
	_init_unit_painter()
	
	#teams ui
	_new_team_button.pressed.connect(_add_new_team)
	#player ui
	_new_player_button.pressed.connect(_add_new_player)
	
	#tab container
	_tab_container.tab_changed.connect(_on_tab_changed)

# links the editor_main object
func link_editor_main(editor_main_p : EditorMain):
	editor_main = editor_main_p

func _reload() -> void:
	#sync team uis in game editor teams tab
	_sync_ui()
	#reload the unit libs in map painter
	_sync_player_libraries()
	#reload the map in map painter
	_sync_map()
	

func _sync_ui() -> void: 
	_sync_team_uis()
	_sync_player_uis()
	_sync_player_key_units()

func _sync_player_key_units() -> void:
	for player_ui in _player_uis:
		_sync_player_key_units_for(player_ui)

func _sync_player_key_units_for(player_ui: PlayerUi) -> void:
	var team_name: String = player_ui.get_selected_team_name()
	if team_name == "":
		player_ui.sync_key_units([])
	else:
		player_ui.sync_key_units(_get_team_unit_names(team_name))

func _get_team_unit_names(team_name: String) -> Array:
	var team_units: Array = []
	for team_ui in _team_uis:
		if team_ui.get_team_name() == team_name:
			team_units = team_ui.get_team_units()
			break
	if team_units.is_empty():
		for team in _teams:
			if team.get_name() == team_name:
				team_units = team.get_units()
				break
	return _order_unit_names(team_units)

#update map based on map editor
func _sync_map() -> void:
	var attribute_grid = editor_main.getMap().get_strategic_map().get_attribute_grids()[0]
	_unit_painter.reload_layer(attribute_grid, _base_layer_id)
	_unit_painter.resize(attribute_grid.width, attribute_grid.height)
	_unit_painter.set_map_name(editor_main.getMap().get_strategic_map().get_map_name())

#sync libraries in map painter based on _teams
func _sync_team_libraries() -> void: 
	var lib_names = _unit_painter.get_library_names()
	var new_lib_names: Array = []
	for team in _teams:
		var team_name = team.get_name()
		if lib_names.has(team_name):
			_unit_painter.sync_library(_generate_team_lib_data(team), team_name)
		else: 
			_unit_painter.add_library(team_name, MapAttributes.UNIT_UNIT_LIB_OVERWRITE, MapAttributes.UNIT_UNIT_LIB_ADD,
									MapAttributes.UNIT_UNIT_LIB_TEXTURE_ID,
									MapAttributes.UNIT_UNIT_LIB_ITEM_ID, _unit_layer_id, false, true)
			_unit_painter.sync_library(_generate_team_lib_data(team), team_name)
		new_lib_names.append(team_name)
	#remove libs that are in the painter but not in teams
	for team_name in lib_names: 
		if !new_lib_names.has(team_name):
			_unit_painter.remove_library(team_name)

func _sync_player_libraries() -> void: 
	var lib_names = _unit_painter.get_library_names()
	var new_lib_names: Array = []
	for player in _players:
		var player_name = player.get_name()
		var player_lib_data = _generate_player_lib_data(player)
		if player_lib_data.is_empty():
			continue
		if lib_names.has(player_name):
			_unit_painter.sync_library(player_lib_data, player_name)
		else: 
			_unit_painter.add_library(player_name, MapAttributes.UNIT_UNIT_LIB_OVERWRITE, MapAttributes.UNIT_UNIT_LIB_ADD,
									MapAttributes.UNIT_UNIT_LIB_TEXTURE_ID,
									MapAttributes.UNIT_UNIT_LIB_ITEM_ID, _unit_layer_id, false, true)
			_unit_painter.sync_library(player_lib_data, player_name)
		new_lib_names.append(player_name)
	#remove libs that are in the painter but not in teams
	for player_name in lib_names: 
		if !new_lib_names.has(player_name):
			_unit_painter.remove_library(player_name)

#teams#
func _add_new_team() -> TeamUi: 
	#add team ui
	var team_ui: TeamUi = preload("res://editor/editors/game_editor/team_ui.tscn").instantiate()
	_teams_container.add_child(team_ui)
	team_ui.init_units(_get_unit_names())
	#team signals
	team_ui.unit_added.connect(_on_team_unit_added.bind(team_ui))
	team_ui.unit_removed.connect(_on_team_unit_removed.bind(team_ui))
	team_ui.name_changed.connect(_on_team_name_changed.bind(team_ui))
	team_ui.color_changed.connect(_on_team_color_changed.bind(team_ui))
	team_ui.units_changed.connect(_on_team_units_changed.bind(team_ui))
	_team_uis.append(team_ui)
	#add GameTeam
	var new_team: GameTeam = GameTeam.new("", Color.RED, _teams.size(), [])
	_teams.append(new_team)
	_sync_player_uis()
	return team_ui

func _clear_players() -> void: 
	_players.clear()
	for player_ui in _player_uis:
		_players_container.remove_child(player_ui)
	_player_uis.clear()

func _clear_teams() -> void: 
	_teams.clear()
	for team_ui in _team_uis: 
		_teams_container.remove_child(team_ui)
	_team_uis.clear()

#update team_uis based on unit editor units
func _sync_team_uis() -> void: 
	#load units from unit editor
	var arr: Array = []
	for unit in editor_main.get_units():
		var unit_name = unit.get_attribute_value("name")
		if unit_name == null: 
			continue
		arr.append(unit_name)
	#sync units
	for i in range(_team_uis.size()):
		_team_uis[i].sync_units(arr)
		if i < _teams.size():
			_teams[i].set_units(_team_uis[i].get_team_units())

#players#
func _add_new_player() -> PlayerUi: 
	var team_names: Array = []
	for team in _teams:
		team_names.append(team.get_name())
	var new_player_ui: PlayerUi = preload("res://editor/editors/game_editor/player_ui.tscn").instantiate() as PlayerUi
	if new_player_ui == null:
		push_error("Failed to instantiate PlayerUi.")
		return null
	_players_container.add_child(new_player_ui)
	new_player_ui.init_teams(team_names)
	_sync_player_key_units_for(new_player_ui)
	_player_uis.append(new_player_ui)
	#signals
	new_player_ui.team_selected.connect(_on_player_team_selected.bind(new_player_ui))
	new_player_ui.team_unselected.connect(_on_player_team_unselected.bind(new_player_ui))
	new_player_ui.name_changed.connect(_on_player_name_changed.bind(new_player_ui))
	var new_player: GamePlayer = GamePlayer.new("", _players.size(), null)
	_players.append(new_player)
	return new_player_ui

#update player uis based on _teams
func _sync_player_uis() -> void: 
	var team_names: Array = []
	for team in _teams:
		team_names.append(team.get_name())
	for player_ui in _player_uis: 
		player_ui.sync_teams(team_names)

func _set_default_state() -> void: 
	_unit_painter.set_to_default_state()

##Signal response
func _on_visibibility_changed() -> void:
	if visible: 
		_reload()
	else:
		_set_default_state()

#team#
func _on_team_unit_added(unit_name: String, sender: TeamUi) -> void: 
	var indx = _team_uis.find(sender)
	if indx == -1 or indx >= _teams.size():
		print("untracked team's signal catched")
		return
	_teams[indx].add_unit(unit_name)

func _on_team_unit_removed(unit_name: String, sender: TeamUi) -> void: 
	var indx = _team_uis.find(sender)
	if indx == -1 or indx >= _teams.size():
		print("untracked team's signal catched")
		return
	_teams[indx].remove_unit(unit_name)

func _on_team_name_changed(new_team_name: String, sender: TeamUi) -> void: 
	var indx = _team_uis.find(sender)
	if indx == -1 or indx >= _teams.size():
		print("untracked team's signal catched")
		return
	_teams[indx].set_name(new_team_name)
	_sync_player_uis()
	_sync_player_key_units()

func _on_team_color_changed(new_team_color: Color, sender: TeamUi) -> void: 
	var indx = _team_uis.find(sender)
	if indx == -1 or indx >= _teams.size():
		print("untracked team's signal catched")
		return
	_teams[indx].set_color(new_team_color)

func _on_team_units_changed(new_units: Array, sender: TeamUi) -> void: 
	var indx = _team_uis.find(sender)
	if indx == -1 or indx >= _teams.size():
		print("untracked team's signal catched")
		return
	_teams[indx].set_units(new_units)
	var team_name: String = sender.get_team_name()
	for player_ui in _player_uis:
		if player_ui.get_selected_team_name() == team_name:
			_sync_player_key_units_for(player_ui)

#player#
func _on_player_team_selected(team_name: String, sender: PlayerUi) -> void: 
	var indx = _player_uis.find(sender)
	if indx == -1 or indx >= _players.size():
		print("untracked player's signal catched")
		return
	for team in _teams: 
		if team.get_name() == team_name:
			_players[indx].set_team(team)
	_sync_player_key_units_for(sender)

func _on_player_team_unselected(team_name: String, sender: PlayerUi) -> void: 
	var indx = _player_uis.find(sender)
	if indx == -1 or indx >= _players.size():
		print("untracked player's signal catched")
		return
	if _players[indx].get_team() != null and _players[indx].get_team().get_name() == team_name:
		_players[indx].set_team(null)
	_sync_player_key_units_for(sender)
func _on_player_name_changed(new_player_name: String, sender: PlayerUi) -> void: 
	var indx = _player_uis.find(sender)
	if indx == -1 or indx >= _players.size():
		print("untracked player's signal catched")
		return
	_players[indx].set_name(new_player_name)

func _on_tab_changed(tab_id: int) -> void: 
	if tab_id == MAP_TAB_ID:
		_sync_player_libraries()


##IMPORT / EXPORT 
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
	game_resource.save_player_uis(_get_player_uis_res())
	game_resource.save_rules(_game_rules.get_rules())
	ftm.download_data(game_resource, game_name + ".tres", "*.tres", true)

func load_from_file() -> void:
	ftm.upload_data("*.tres", true)

func load_from_resource(resource : GameDefinitionResource):
	set_game_name(resource.game_name)
	editor_main.set_units(resource.load_units())
	editor_main.setMap(resource.loadMap())
	_unit_painter.reload_layer(resource.load_unit_layer(), _unit_layer_id)
	_game_rules.import(resource.load_rules())
	#teams
	_clear_teams()
	for team_ui_res in resource.load_team_uis():
		_add_new_team().import(team_ui_res)
	#players
	_clear_players()
	for player_ui_res in resource.load_player_uis():
		_add_new_player().import(player_ui_res)
	_reload()

func _init_unit_painter() -> void: 
	_unit_painter.init_painter(10, 10)
	_base_layer_id = _unit_painter.add_layer(MapAttributes.STRATEGIC_TEXTURE_ID, MapAttributes.STRATEGIC_TILE_ID)
	_unit_layer_id = _unit_painter.add_layer(MapAttributes.UNIT_TEXTURE_ID, MapAttributes.UNIT_TILE_ID)
	_unit_painter.set_active_layer(_unit_layer_id)


##Setters / Getters
func get_game_name() -> String:
	return game_name_line.text

func set_game_name(name_p : String):
	game_name_line.text = name_p
	
func _get_team_uis_res() -> Array[TeamUiRes]: 
	var out: Array[TeamUiRes] = []
	for team_ui in _team_uis: 
		out.append(team_ui.export())
	return out

func _get_player_uis_res() -> Array[PlayerUiRes]:
	var out: Array[PlayerUiRes] = []
	for player_ui in _player_uis: 
		out.append(player_ui.export())
	return out

##Utility functions
func _generate_team_lib_data(team: GameTeam) -> Array: 
	var data: Array = []
	var team_units = team.get_units()
	for unit in editor_main.get_units():
		var unit_name: String = unit.get_attribute_value("name")
		var unit_texture_img: Texture2D = unit.get_attribute_value("texture")
		if unit_name == null or unit_texture_img == null: 
			continue
		if !team_units.has(unit_name):
			continue
		var unit_texture: Texture2D = _generate_colored_unit_texture(team.get_color(), unit_texture_img)
		var datapoint: Dictionary[String, Variant] = {
			MapAttributes.UNIT_UNIT_LIB_ITEM_ID: unit_name,
		 	MapAttributes.UNIT_UNIT_LIB_TEXTURE_ID: unit_texture,
			MapAttributes.UNIT_TEAM_ID: team.get_name()}
		data.append(datapoint)
	return data

func _generate_player_lib_data(player: GamePlayer) -> Array: 
	var team = player.get_team()
	if team == null: 
		return []
	var out = _generate_team_lib_data(team)
	for datapoint in out: 
		datapoint["player"] = player.get_name()
	return out


func _get_unit_names() -> Array:
	var data: Array = []
	for unit in editor_main.get_units():
		var unit_name: String = unit.get_attribute("name").attribute_value
		data.append(unit_name)
	return data

func _order_unit_names(unit_names: Array) -> Array:
	var ordered: Array = []
	for unit_name in _get_unit_names():
		if unit_names.has(unit_name) and not ordered.has(unit_name):
			ordered.append(unit_name)
	for unit_name in unit_names:
		if not ordered.has(unit_name):
			ordered.append(unit_name)
	return ordered

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
