extends Node
class_name PlayerUi

const KEY_UNIT_OPTION_PATH := "EditorPanel/TopVBox/ScrollContainer/ContentsVBox/KeyUnitHBox/OptionButton"

@onready var _teams_vbox = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/TeamsVbox
@onready var _player_name_ui = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/HBoxContainer/LineEdit
@onready var _panel = $EditorPanel


var _teams: Dictionary[String, bool] = {}
var _team_uis: Dictionary[String, LabelCheckbox] = {}

##signals
signal team_unselected(team_name: String)
signal team_selected(team_name: String)
signal name_changed(new_name: String)
signal player_removed()


##State functions
func _ready() -> void:
	_player_name_ui.text_changed.connect(_on_name_changed)
	_panel.close_button_pressed.connect(_on_close_button_pressed)


func sync_teams(teams: Array) -> void: 
	for inc_team_name in teams: 
		_teams[inc_team_name] = _teams.get(inc_team_name, false)
	var to_be_removed: Array = []
	for team_name in _teams:
		if !teams.has(team_name):
			to_be_removed.append(team_name)
	for rem in to_be_removed:
		_teams.erase(rem)
	_sync_ui()

func reload_teams(teams: Dictionary) -> void:
	_teams = teams
	for team in _teams.keys():
		if _teams[team]:
			team_selected.emit(team)
	_sync_ui()

func init_teams(teams: Array) -> void: 
	for team_name in teams: 
		_teams[team_name] = false
	_sync_ui()

##Signal response
func _sync_ui() -> void:
	for team_name in _team_uis:
		_teams_vbox.remove_child(_team_uis[team_name])
	_team_uis.clear()
	for team_name in _teams.keys():
		var new_team_ui: LabelCheckbox = preload("res://editor/editors/game_editor/label_checkbox.tscn").instantiate()
		_team_uis[team_name] = new_team_ui
		#add to tree before calling functions
		_teams_vbox.add_child(new_team_ui)
		#signals
		new_team_ui.box_checked.connect(_team_checked.bind(team_name))
		new_team_ui.box_unchecked.connect(_team_unchecked.bind(team_name))
		#set name and state
		new_team_ui.set_label_text(team_name)
		if _teams[team_name]:
			new_team_ui.set_box_on()

func _sync_ui_states() -> void:
	for team_name in _teams: 
		if !_team_uis.has(team_name):
			continue
		if _teams[team_name]: 
			_team_uis[team_name].set_box_on()
		else:
			_team_uis[team_name].set_box_off()

func _team_checked(team_name: String) -> void: 
	for t_name in _teams.keys(): 
		_teams[t_name] = false
	_teams[team_name] = true
	_sync_ui_states()
	team_selected.emit(team_name)

func _team_unchecked(team_name: String) -> void: 
	_teams[team_name] = false
	_sync_ui_states()
	team_unselected.emit(team_name)


func _on_name_changed(new_name: String) -> void:
	name_changed.emit(new_name)

func get_selected_team_name() -> String:
	for team_name in _teams.keys():
		if _teams[team_name]:
			return team_name
	return ""

func _get_key_unit_option() -> OptionButton:
	return get_node_or_null(KEY_UNIT_OPTION_PATH) as OptionButton

func sync_key_units(unit_names: Array) -> void:
	if not is_node_ready():
		call_deferred("sync_key_units", unit_names)
		return
	var option := _get_key_unit_option()
	if option == null:
		return
	var selected_name := _get_selected_key_unit_name()
	option.clear()
	option.add_item("")
	for unit_name in unit_names:
		if unit_name == "" or _option_has_item(option, unit_name):
			continue
		option.add_item(unit_name)
	_set_selected_key_unit_name(selected_name)

func _option_has_item(option: OptionButton, item_text: String) -> bool:
	for i in range(option.item_count):
		if option.get_item_text(i) == item_text:
			return true
	return false

func _get_selected_key_unit_name() -> String:
	var option := _get_key_unit_option()
	if option == null or option.item_count == 0:
		return ""
	var index := option.selected
	if index < 0:
		return ""
	return option.get_item_text(index)

func _set_selected_key_unit_name(unit_name: String) -> void:
	var option := _get_key_unit_option()
	if option == null:
		return
	for i in range(option.item_count):
		if option.get_item_text(i) == unit_name:
			option.select(i)
			return
	option.select(0)
	
func _on_close_button_pressed():
	player_removed.emit()

##IMPORT / EXPORT
func import(res: PlayerUiRes) -> void: 
	reload_teams(res.get_teams())
	_player_name_ui.text = res.get_player_name()
	name_changed.emit(res.get_player_name())
	call_deferred("_apply_imported_key_unit", res.get_key_unit_type_name())

func _apply_imported_key_unit(unit_name: String) -> void:
	_set_selected_key_unit_name(unit_name)

func export() -> PlayerUiRes: 
	var res = PlayerUiRes.new()
	res.init(_teams, _player_name_ui.text, _get_selected_key_unit_name())
	return res


#
