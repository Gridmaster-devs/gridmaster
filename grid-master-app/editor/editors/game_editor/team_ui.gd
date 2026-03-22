extends Node
class_name TeamUi


@onready var _color_button: Button = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/HBoxContainer/ColorButton
@onready var _team_color_rect: TextureRect = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/HBoxContainer/TeamColor
@onready var _team_name_ui: LineEdit = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Name/TeamName
@onready var _content_vbox: VBoxContainer = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox



var _color: Color
var _units: Dictionary[String, bool] = {}
var _unit_uis: Dictionary[String, LabelCheckbox] = {}

##signals
signal unit_added(unit: String)
signal unit_removed(unit: String)
signal name_changed(new_name: String)
signal color_changed(new_color: Color)

##State functions
func _ready() -> void:
	_color_button.pressed.connect(_open_color_picker)
	_team_name_ui.text_changed.connect(_on_name_changed)

func reload_units(units: Dictionary) -> void:
	_units = units
	_sync_ui()

func init_units(units: Array) -> void: 
	for unit_name in units: 
		_units[unit_name] = false
	_sync_ui()
	
func sync_units(units: Array) -> void: 
	for inc_unit_name in units: 
		_units[inc_unit_name] = _units.get(inc_unit_name, false)
	var to_be_removed: Array = []
	for unit_name in _units:
		if !units.has(unit_name):
			to_be_removed.append(unit_name)
	for rem in to_be_removed:
		_units.erase(rem)
	_sync_ui()

func _sync_ui() -> void:
	#color
	var img = Image.create_empty(Global.tile_width, Global.tile_height, false, Image.FORMAT_RGBA8)
	img.fill(_color)
	_team_color_rect.texture = ImageTexture.create_from_image(img)
	#units
	for unit_name in _unit_uis:
		_content_vbox.remove_child(_unit_uis[unit_name])
	_unit_uis.clear()
	for unit_name in _units.keys():
		var new_unit_ui: LabelCheckbox = preload("res://editor/editors/game_editor/label_checkbox.tscn").instantiate()
		_unit_uis[unit_name] = new_unit_ui
		#add to tree before calling functions
		_content_vbox.add_child(new_unit_ui)
		#signals
		new_unit_ui.box_checked.connect(_unit_checked.bind(unit_name))
		#set name and state
		new_unit_ui.set_label_text(unit_name)
		if _units[unit_name]:
			new_unit_ui.set_box_on()


##Signal response
func _on_name_changed(new_name: String) -> void:
	name_changed.emit(new_name)
	
func _open_color_picker() -> void:
	var color_picker_popup: TextureColorPicker = preload("res://common/popups/color_picker.tscn").instantiate()
	color_picker_popup.add_to_tree()
	color_picker_popup.color_saved.connect(_on_color_picker_color)
	color_picker_popup.texture_saved.connect(_on_color_picker_texture)

func _on_color_picker_color(color: Color) -> void: 
	_color = color
	color_changed.emit(color)
	
func _on_color_picker_texture(tex: Texture2D) -> void:
	_team_color_rect.texture = tex

func _unit_checked(unit_name: String) -> void:
	_units[unit_name] = true
	unit_added.emit(unit_name)

func _unit_unchecked(unit_name: String) -> void:
	_units[unit_name] = false
	unit_removed.emit(unit_name)

##IMPORT / EXPORT
func export() -> TeamUiRes: 
	var res: TeamUiRes = TeamUiRes.new()
	res.init(_units, _team_name_ui.text, _color)
	return res

func import(res: TeamUiRes) -> void: 
	_units = res.get_units()
	_color = res.get_team_color()
	_team_name_ui.text = res.get_team_name()
	_sync_ui()


##Getters / Setters
func get_team_color() -> Color:
	return _color

func get_team_name() -> String: 
	return _team_name_ui.text

func get_team_units() -> Array:
	var out: Array = []
	for key in _units.keys():
		if _units[key]:
			out.append(key)
	return out

#
