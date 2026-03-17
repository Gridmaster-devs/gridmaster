extends Node
class_name PaintLibrary


@onready var _new_button: Button = $ButtonsContainer/VBoxContainer/NewButton
@onready var _new_button_container: VBoxContainer = $ButtonsContainer/VBoxContainer
@onready var _buttons_container = $ButtonsContainer
@onready var _name_ui = $LibName
@onready var _remove_button = $HBoxContainer/Remove

##signals
signal lib_item_pressed(addable: Dictionary[String, Variant], 
							overwrite: Dictionary[String, Variant], highlight: bool, layer_id: int)

signal lib_item_removed(lib_name: String, item_id: String, item_id_value: Variant, layer_id: int)

signal lib_item_added(data: Dictionary[String, Variant], _lib_name: String)

##variables
var _overwrite_data: Dictionary[String, Variant]
var _addable_data: Dictionary[String, Variant]

var _preview_texture_id: String
var _item_id: String

var _items: Array[Node]
var _name: String

var _highlight: bool

var _layer_id: int

#tracking which item is active
var _cur_item_data: Dictionary



func init(lib_name: String, preview_texture_id: String, item_id: String,
				overwrite_data: Dictionary[String, Variant], addable_data: Dictionary[String, Variant], 
				layer_id: int, new_button: bool = false, highlight: bool = false, 
				new_button_callback: Callable = Callable()) -> void: 
	if !new_button: 
		_new_button_container.visible = false
	_highlight = highlight
	_name = lib_name
	_preview_texture_id = preview_texture_id
	_item_id = item_id
	_overwrite_data = overwrite_data
	_addable_data = addable_data
	_layer_id = layer_id
	
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
	var new_tile_popup: NewTilePopup = preload("res://editor/editors/map_editor_refactor/popup_windows/new_tile_popup.tscn").instantiate()
	new_tile_popup.add_to_tree()
	##INIT HAS TO BE CALLED AFTER BEING ADDED TO TREE
	
	var display_types: Dictionary[String, Variant]
	for key in _overwrite_data:
		display_types[key] = _overwrite_data[key]
	for key in _addable_data:
		display_types[key] = _addable_data[key]
	new_tile_popup.init(display_types, _name)
	new_tile_popup.new_tile_confirmed.connect(_on_new_tile_confirmed)

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
	lib_item_pressed.emit(addable, overwrite, highlight, _layer_id)
	


func _open_item_dropdown() -> void: 
	var dropdown: DropDown = preload("res://editor/editors/map_editor_refactor/drop_down/drop_down.tscn").instantiate()
	dropdown.add_to_tree()

func _remove_item() -> void: 
	if _cur_item_data.has(_item_id):
		lib_item_removed.emit(_name, _item_id, _cur_item_data[_item_id], _layer_id)


##getters / setters
func get_item_id() -> String: 
	return _item_id

func get_layer_id() -> int: 
	return _layer_id

func _open_remove_confirm_popup() -> void: 
	var confirm_popup: ConfirmPopup = preload("res://common/popups/confirm_popup.tscn").instantiate()
	confirm_popup.add_to_tree()
	confirm_popup.ok.connect(_on_remove_confirm)

	
func _on_remove_confirm() -> void:
	_remove_item()
	

func _on_new_tile_confirmed(data: Dictionary[String, Variant], lib_name: String) -> void: 
	lib_item_added.emit(data, lib_name)






##
