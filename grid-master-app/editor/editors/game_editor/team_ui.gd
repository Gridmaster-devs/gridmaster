extends Node
class_name TeamUi


@onready var _color_button: Button = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/HBoxContainer/ColorButton
@onready var _team_color_rect: TextureRect = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/HBoxContainer/TeamColor
@onready var _team_name_ui: LineEdit = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Name/TeamName
@onready var _content_vbox: VBoxContainer = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox
var _color: Color

var _team_checked_dictionary: Dictionary[String, bool] = {}

var _team_unit_type_uis: Dictionary[String, TeamUnitType] = {}

func _ready() -> void:
	_color_button.pressed.connect(_open_color_picker)

func init_units(unit_names: Array) -> void: 
	for unit_name in unit_names: 
		if !_team_checked_dictionary.has(unit_name):
			_team_checked_dictionary[unit_name] = false
		var unit_type_ui: TeamUnitType = preload("res://editor/editors/game_editor/team_unit_type.tscn").instantiate()
		_content_vbox.add_child(unit_type_ui)
		unit_type_ui.set_unit_name(unit_name)
		unit_type_ui.box_checked.connect(_on_team_on.bind(unit_name))
		unit_type_ui.box_unchecked.connect(_on_team_off.bind(unit_name))
		_team_unit_type_uis[unit_name] = unit_type_ui

func sync_units(units: Array) -> void: 
	for unit_name in units: 
		if !_team_checked_dictionary.has(unit_name):
			_team_checked_dictionary[unit_name] = false
		if _team_unit_type_uis.has(unit_name):
			continue
		var unit_type_ui: TeamUnitType = preload("res://editor/editors/game_editor/team_unit_type.tscn").instantiate()
		_content_vbox.add_child(unit_type_ui)
		unit_type_ui.set_unit_name(unit_name)
		unit_type_ui.box_checked.connect(_on_team_on.bind(unit_name))
		unit_type_ui.box_unchecked.connect(_on_team_off.bind(unit_name))
		_team_unit_type_uis[unit_name] = unit_type_ui
	for unit_name in _team_checked_dictionary: 
		if !units.has(unit_name):
			_content_vbox.remove_child(_team_unit_type_uis[unit_name])
			_team_unit_type_uis.erase(unit_name)
			_team_checked_dictionary.erase(unit_name)
			
	_sync_uis()


func _open_color_picker() -> void:
	var color_picker_popup: TextureColorPicker = preload("res://common/popups/color_picker.tscn").instantiate()
	color_picker_popup.add_to_tree()
	color_picker_popup.color_saved.connect(_on_color_picker_color)
	color_picker_popup.texture_saved.connect(_on_color_picker_texture)

func _on_color_picker_color(color: Color) -> void: 
	_color = color
	
func _on_color_picker_texture(tex: Texture2D) -> void:
	_team_color_rect.texture = tex

func get_team_color() -> Color:
	return _color

func get_team_name() -> String: 
	return _team_name_ui.text

func get_team_units() -> Array:
	var out: Array = []
	for key in _team_checked_dictionary.keys():
		if _team_checked_dictionary[key]:
			out.append(key)
	return out

func _on_team_on(unit_name: String) -> void:
	_team_checked_dictionary[unit_name] = true

func _on_team_off(unit_name: String) -> void:
	_team_checked_dictionary[unit_name] = false

func _clear_unit_uis() -> void: 
	for key in _team_unit_type_uis.keys(): 
		_content_vbox.remove_child(_team_unit_type_uis[key])
		_team_unit_type_uis.erase(key)

func export() -> TeamUiRes: 
	var res: TeamUiRes = TeamUiRes.new()
	res.init(_team_checked_dictionary, _team_name_ui.text, _color)
	return res

func import(res: TeamUiRes) -> void: 
	_clear_unit_uis()
	_team_checked_dictionary = res.get_units()
	_color = res.get_team_color()
	_team_name_ui.text = res.get_team_name()
	init_units(_team_checked_dictionary.keys())
	_sync_uis()




func _sync_uis() -> void: 
	#color
	var img = Image.create_empty(Global.tile_width, Global.tile_height, false, Image.FORMAT_RGBA8)
	img.fill(_color)
	_team_color_rect.texture = ImageTexture.create_from_image(img)
	#units
	for key in _team_checked_dictionary.keys():
		if _team_checked_dictionary[key]:
			_team_unit_type_uis[key].set_box_on()
		else:
			_team_unit_type_uis[key].set_box_off()


#
