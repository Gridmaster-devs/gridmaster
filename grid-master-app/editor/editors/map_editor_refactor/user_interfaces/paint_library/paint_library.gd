extends Node
class_name PaintLibrary


@onready var _new_button = $ButtonsContainer/VBoxContainer/NewButton
@onready var _buttons_container = $ButtonsContainer
@onready var _name_ui = $LibName
@onready var _remove_button = $HBoxContainer/Remove

##signals
signal lib_item_pressed(addable: Dictionary[String, Variant], 
							overwrite: Dictionary[String, Variant], highlight: bool)

signal lib_item_removed(lib_name: String, item_id: String, item_id_value: Variant)

##variables
var _overwrite_data: Dictionary[String, Variant]
var _addable_data: Dictionary[String, Variant]

var _preview_texture_id: String
var _item_id: String

var _items: Array[Node]
var _name: String

var _highlight: bool

#tracking which item is active
var _cur_item_data: Dictionary



func init(lib_name: String, preview_texture_id: String, item_id: String,
				overwrite_data: Dictionary[String, Variant], addable_data: Dictionary[String, Variant], 
				highlight: bool = false, new_button_callback: Callable = Callable()) -> void: 
	_highlight = highlight
	_name = lib_name
	_preview_texture_id = preview_texture_id
	_item_id = item_id
	_overwrite_data = overwrite_data
	_addable_data = addable_data
	
	#Ui
	_name_ui.text = " " + _name
	#new button callback:
	if new_button_callback.is_null():
		_new_button.pressed.connect(_on_new_tile_button_pressed)
	else: 
		_new_button.pressed.connect(new_button_callback)
	#connect remove and edit
	_remove_button.pressed.connect(_open_remove_confirm_popup)
	
#function that gets called when the new button is pressed
#the button with a '+' 
func _on_new_tile_button_pressed() -> void: 
	var _new_tile_popup = preload("res://editor/editors/map_editor_refactor/popup_windows/new_tile_popup.tscn").instantiate()
	get_tree().call_group("map_painter_popup_manager", "add_new_popup", _new_tile_popup, _new_tile_popup.get_popup_name())
	##INIT HAS TO BE CALLED AFTER BEING ADDED TO TREE
	
	var display_types: Dictionary[String, Variant]
	for key in _overwrite_data:
		display_types[key] = _overwrite_data[key]
	for key in _addable_data:
		display_types[key] = _addable_data[key]
	_new_tile_popup.init(display_types, _name)

#clears the items on the library
func _clear_items() -> void: 
	for item in _items: 
		item.queue_free()
	_items.clear()

#adds an item to the library 
#(a button that when clicked can be used to paint the map)
#datapoint contains the both overwrite data and addable data
#the datapoint is passed to buttonCallback, where it will differentiate
func _add_lib_item(datapoint: Dictionary[String, Variant]) -> void:
	if datapoint.has(_preview_texture_id) and datapoint.has(_item_id): 
		var new_item: LibraryItem = preload("res://editor/editors/map_editor_refactor/user_interfaces/paint_library/library_item.tscn").instantiate()
		_buttons_container.add_child(new_item)
		new_item.set_data(datapoint[_item_id], datapoint[_preview_texture_id])
		new_item.get_button().pressed.connect(_button_callback.bind(datapoint))
		_items.append(new_item)
		
	
#completely recreates the lib items based on the array
#data is an array of datapoints (Dictionary[String, Variant])
func initialize_lib_items(data: Array[Variant]) -> void: 
	_clear_items()
	for datapoint in data: 
		_add_lib_item(datapoint)


#the callback function for each library button besides the "New button"
func _button_callback(datapoint: Dictionary[String, Variant]) -> void: 
	_cur_item_data = datapoint
	var addable: Dictionary[String, Variant] = {}
	var overwrite: Dictionary[String, Variant] = {}
	var highlight: bool = _highlight
	if !_addable_data.is_empty():
		for key in _addable_data:
			addable[key] = datapoint[key]
	if !_overwrite_data.is_empty():
		for key in _overwrite_data:
			overwrite[key] = datapoint[key]
	lib_item_pressed.emit(addable, overwrite, highlight)
	


func _open_item_dropdown() -> void: 
	var dropdown: DropDown = preload("res://editor/editors/map_editor_refactor/drop_down/drop_down.tscn").instantiate()
	get_tree().call_group("map_painter_popup_manager", "add_new_popup", dropdown.get)

func _remove_item() -> void: 
	if _cur_item_data.has(_item_id):
		lib_item_removed.emit(_name, _item_id, _cur_item_data[_item_id])


##getters / setters
func get_item_id() -> String: 
	return _item_id



func _open_remove_confirm_popup() -> void: 
	var confirm_popup: ConfirmPopup = preload("res://editor/editors/map_editor_refactor/popup_windows/confirm_popup.tscn").instantiate()
	get_tree().call_group("map_painter_popup_manager", "add_new_popup", confirm_popup,  confirm_popup.get_popup_name())
	confirm_popup.cancel.connect(_on_remove_cancel.bind(confirm_popup.get_popup_name()))
	confirm_popup.ok.connect(_on_remove_confirm.bind(confirm_popup.get_popup_name()))
	
func _on_remove_cancel(popup_name: String) -> void:
	get_tree().call_group("map_painter_popup_manager", "close_popup", popup_name)
	
func _on_remove_confirm(popup_name: String) -> void:
	_remove_item()
	_on_remove_cancel(popup_name)
	









##
