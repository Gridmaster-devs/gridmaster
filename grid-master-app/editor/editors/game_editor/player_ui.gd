extends Control
class_name PlayerUi


@onready var _teams_vbox = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/TeamsVbox
@onready var _player_name_ui = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/HBoxContainer/LineEdit


var _teams: Dictionary[String, bool] = {}
var _team_uis: Dictionary[String, LabelCheckbox] = {}

##signals
signal team_selected(unit: String)
signal name_changed(new_name: String)

##State functions
func _ready() -> void:
	_player_name_ui.text_changed.connect(_on_name_changed)


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

func _on_name_changed(new_name: String) -> void:
	name_changed.emit(new_name)

##IMPORT / EXPORT
func import(res: PlayerUiRes) -> void: 
	reload_teams(res.get_teams())
	_player_name_ui.text = res.get_player_name()

func export() -> PlayerUiRes: 
	var res = PlayerUiRes.new()
	res.init(_teams, _player_name_ui.text)
	return res


#
