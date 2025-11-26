@tool
class_name PanelItem
extends VBoxContainer

@export var text : String
@export_enum("Field", "Checkbox", "Dropdown") var type : int
@export_tool_button("Update Item", "Callable") var update_action = update_item

var items : Array[String] = []
var label_path = "HBoxContainer/ItemName"

# THIS IS THE ISSUE, GETS RESET WHEN THE SCENE IS NOT LIVE
# REPLACE THE USAGE OF THIS WITH ABSOLUTE PATHS FOR GETTERS AND SETTERS
# ALSO NOTICE THAT THE TOOL SCRIPT FUNCTION THAT MAKES THE DROPDOWN USES THIS
# TO SET VALUES IN EDITOR; THIS IS NOT USELESS, JUST NOT FIT FOR GET_VALUE AND SET_VALUE
# (the get and set at the bottom relate to godot's internal logic and work fine
# this problem has to do with the top most functions)
var value_container_path = ""


func get_value():
	match type:
		0:
			var node : LineEdit = get_node(value_container_path) as LineEdit
			return node.text
		1:
			var node : CheckBox = get_node(value_container_path) as CheckBox
			return node.is_pressed()
		2:
			var node : OptionButton = get_node(value_container_path) as OptionButton
			var index = node.selected
			return items[index]
			
func set_value(val): 
	match type:
		0:
			var node : LineEdit = get_node(value_container_path) as LineEdit
			node.text = val
		1:
			var node : CheckBox = get_node(value_container_path) as CheckBox
			node.set_pressed(val)
		2:
			var node : OptionButton = get_node(value_container_path) as OptionButton
			node.selected = val

func update_item():
	if Engine.is_editor_hint():
		update_type()
		update_text()
		update_dropdown()
		notify_property_list_changed()
		
func update_type():
	if Engine.is_editor_hint():
		for child in self.get_children():
			self.remove_child(child)
		match type:
			0:
				make_field_item()
			1:
				make_checkbox_item()
			2:
				make_dropdown_item()

func update_text(): 
	if text.is_empty():
		text = self.name
	get_node(label_path).text = text
	self.name = text

func update_dropdown():
	if type == 2:
		var dropdown = get_node(value_container_path) as OptionButton
		for i in dropdown.item_count:
			dropdown.remove_item(i)
		for item in items:
			dropdown.add_item(item)
	
func make_field_item():
	var root = get_tree().edited_scene_root
	var container = HBoxContainer.new()
	var label = Label.new()
	var line_edit = LineEdit.new()
	
	self.add_child(container, true)
	container.add_child(label, true)
	container.add_child(line_edit, true)
	
	container.owner = root
	label.owner = root
	line_edit.owner = root
	
	container.set_anchors_preset(PRESET_HCENTER_WIDE, true)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_path = label.get_path()
	value_container_path = line_edit.get_path()
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	line_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	line_edit.editable = true
	
func make_checkbox_item(): 
	var root = get_tree().edited_scene_root
	var container = HBoxContainer.new()
	var label = Label.new()
	var checkbox = CheckBox.new()
	
	self.add_child(container, true)
	container.add_child(label, true)
	container.add_child(checkbox, true)
	
	container.owner = root
	label.owner = root
	checkbox.owner = root
	
	container.set_anchors_preset(PRESET_HCENTER_WIDE, true)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_path = label.get_path()
	value_container_path = checkbox.get_path()
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	checkbox.size_flags_horizontal = SIZE_EXPAND_FILL
	checkbox.set_disabled(false)
	
func make_dropdown_item():
	var root = get_tree().edited_scene_root
	var container = HBoxContainer.new()
	var label = Label.new()
	var dropdown = OptionButton.new()
	
	self.add_child(container, true)
	container.add_child(label, true)
	container.add_child(dropdown, true)
	
	container.owner = root
	label.owner = root
	dropdown.owner = root
	
	container.set_anchors_preset(PRESET_HCENTER_WIDE, true)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_path = label.get_path()
	value_container_path = dropdown.get_path()
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	dropdown.size_flags_horizontal = SIZE_EXPAND_FILL
	dropdown.set_disabled(false)

func _get_property_list():
	var properties = []
	match type:
		0:
			pass
		1: 
			pass
		2:
			properties.append({
				"name": "items",
				"type": TYPE_ARRAY,
				"hint": PROPERTY_HINT_ARRAY_TYPE,
				"hint_string": "%d/%d:" % [TYPE_STRING, PROPERTY_HINT_NONE]
			})
	return properties
	
func _get(property):
	if property == "items":
		return items
		
func _set(property, value):
	if property == "items":
		items = value
		return true
	return false
	
func _ready():
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE
