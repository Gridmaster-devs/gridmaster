extends PopupWindow
class_name SettingsPopup


@onready var _settings_container: VBoxContainer = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/SettingsVbox
@onready var _save_button: Button = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/VBoxContainer/Save
@onready var _cancel_button: Button = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/VBoxContainer/Cancel

var _tiledata_ui_map: Dictionary[String, Node]
var _settings_types: Dictionary[String, Variant]

signal saved(data: Dictionary[String, Variant])

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_save_button.pressed.connect(on_save)
	_cancel_button.pressed.connect(on_cancel)

func _init() -> void: 
	super.set_popup_name("settings_popup")
	
#initializes the settings popup based on the types given
func init(settings_types: Dictionary[String, Variant]) -> void: 
	_settings_types = settings_types
	_init_ui(settings_types)

#generates the UI based on the datatypes in "settings_types"
func _init_ui(settings_types: Dictionary[String, Variant]) -> void: 
	for key in settings_types.keys(): 
		var value = settings_types[key]
		var tile_attribute_hbox = HBoxContainer.new()
		tile_attribute_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var tile_attribute_name_ui = Label.new()
		tile_attribute_name_ui.text = key 
		tile_attribute_name_ui.custom_minimum_size = Vector2(80, 0)
		
		var tile_attribute_value_ui: Node
		
		##checks what type of attribute the current value in the dictionary is
		##and approriately creates a matching ui element
		if value is int or value is float or value is String:
			tile_attribute_value_ui = _create_line_edit()
		else: 
			continue
		_tiledata_ui_map[key] = tile_attribute_value_ui
		tile_attribute_hbox.add_child(tile_attribute_name_ui)
		tile_attribute_hbox.add_child(tile_attribute_value_ui)
		##add the attribute description to the description UI on the right panel
		_settings_container.add_child(tile_attribute_hbox)

##private helper functions to create a simple ui elements
##used when making the tile description ui
func _create_line_edit() -> LineEdit: 
		var line_edit = LineEdit.new()
		line_edit.placeholder_text = ""
		line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		return line_edit
		
func get_settings_data() -> Dictionary[String, Variant]:
	var out_dict:  Dictionary[String, Variant]
	for key in _tiledata_ui_map: 
		var ui_value = _tiledata_ui_map[key]
		var value = _settings_types[key]
		if ui_value is LineEdit:
			if value is int:
				out_dict[key] = int(ui_value.text)
			elif value is float: 
				out_dict[key] = float(ui_value.text)
			elif value is String: 
				out_dict[key] = String(ui_value.text)
	return out_dict
		
func on_save() -> void: 
	saved.emit(get_settings_data())
	get_tree().call_group(Global.popup_manager_group, Global.close_popup, get_popup_name())

func on_cancel() -> void: 
	get_tree().call_group(Global.popup_manager_group, Global.close_popup, get_popup_name())















#
