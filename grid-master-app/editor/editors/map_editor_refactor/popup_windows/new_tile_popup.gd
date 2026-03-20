extends PopupWindow
class_name NewTilePopup



##ui variables
@onready var _attributes_container: VBoxContainer = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/AttributesVbox
@onready var _save_button: Button = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/SaveButton
@onready var _cancel_button: Button = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/CancelButton

signal new_tile_confirmed(data: Dictionary[String, Variant], _lib_name: String)


var _lib_name: String = "unknown"

##tile_data
var _tiledata_ui_map: Dictionary[String, Node]
var _tile_attribute_types: Dictionary[String, Variant]

##ALL POPUPS MUST HAVE
func _init() -> void: 
	super.set_popup_name("new_tile_popup")

##private helper functions to create a simple ui elements
##used when making the tile description ui
func _create_line_edit() -> LineEdit: 
		var line_edit = LineEdit.new()
		line_edit.placeholder_text = ""
		line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		return line_edit

func _ready() -> void: 
	_save_button.pressed.connect(on_new_tile_save)
	_cancel_button.pressed.connect(on_new_tile_cancel)
	center()

func init(tile_attribute_types: Dictionary[String, Variant], lib_name: String) -> void: 
	_tile_attribute_types = tile_attribute_types
	_init_ui(tile_attribute_types)
	_lib_name = lib_name
	

##creates the UI for the 
func _init_ui(tile_attribute_types: Dictionary[String, Variant]) -> void: 
	for key in tile_attribute_types.keys(): 
		var value = tile_attribute_types[key]
		var tile_attribute_hbox = HBoxContainer.new()
		tile_attribute_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var tile_attribute_name_ui = Label.new()
		tile_attribute_name_ui.text = key 
		tile_attribute_name_ui.custom_minimum_size = Vector2(80, 0)
		
		var tile_attribute_value_ui: Node
		
		##checks what type of attribute the current value in the dictionary is
		##and approriately creates a matching ui element
		if value is int:
			tile_attribute_value_ui = _create_line_edit()
		elif value is float:
			tile_attribute_value_ui = _create_line_edit()
		elif value is String: 
			tile_attribute_value_ui = _create_line_edit()
		elif value is Texture2D: 
			tile_attribute_value_ui = preload("res://editor/editors/map_editor_refactor/popup_windows/texture_selecter.tscn").instantiate()
		_tiledata_ui_map[key] = tile_attribute_value_ui
		tile_attribute_hbox.add_child(tile_attribute_name_ui)
		tile_attribute_hbox.add_child(tile_attribute_value_ui)
		##add the attribute description to the description UI on the right panel
		_attributes_container.add_child(tile_attribute_hbox)

func get_ui_element(key: String) -> Node: 
	return _tiledata_ui_map[key]

func get_tile_data() -> Dictionary[String, Variant]: 
	var out_dict:  Dictionary[String, Variant]
	for key in _tiledata_ui_map: 
		var ui_value = _tiledata_ui_map[key]
		var value = _tile_attribute_types[key]
		if ui_value is LineEdit:
			if value is int:
				out_dict[key] = int(ui_value.text)
			elif value is float: 
				out_dict[key] = float(ui_value.text)
			elif value is String: 
				out_dict[key] = String(ui_value.text)
		elif ui_value is HBoxContainer:
				out_dict[key] = ui_value.get_texture()
	return out_dict

func on_new_tile_save() -> void: 
	var data = get_tile_data()
	if _is_valid(data):
		new_tile_confirmed.emit(data, _lib_name)
	remove_from_tree()
	
func on_new_tile_cancel() -> void: 
	remove_from_tree()




#checks if the data has any item that is null or empty
#returns false if finds empty or null values, true otherwise
func _is_valid(data: Dictionary[String, Variant]) -> bool:
	if data.keys().is_empty():
		return false
	for key in data.keys(): 
		var value = data[key]
		if value == null:
			return false
		elif len(str(value)) == 0:
			return false
	return true






##
