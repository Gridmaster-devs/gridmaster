@tool
class_name UnitPanelItem
extends HBoxContainer

enum PanelType {FIELD, CHECKBOX, DROPDOWN, SPINBOX}

# this is the name of the attribute that will be saved in the dictionary
@export var attribute_name : String

# the text that will be shown to the user, explains the attribute
@export var text : String

# reasonably you could and should make these into their own subclass scenes
# which can then be created as a child for this scene, like the actions work
# this would make implementing more complex values far easier, and isn't that much work
@export_enum("Field", "Checkbox", "Dropdown", "Spinbox") var type : int
@export_tool_button("Update Item", "Callable") var update_action = update_item

# various flags
# the resource flag determines whether the attribute counts as a resource, and thus
# whether it shows up in places for resources, like certain actions
@export_flags ("Resource") var flags : int = 0
var root_editor : UnitEditor

var items : Array[String] = [] # Array for the dropdown menu option

# The label is always child 0, and the content (field, checkbox, etc) is always child 1
func get_label():
	# assert(has_type == true, "the panel item has not been given a type, and thus does not have any children")
	return get_child(0)
	
func get_content():
	# assert(has_type == true, "the panel item has not been given a type, and thus does not have any children")
	return get_child(1)
	
func reset():
	match type:
		PanelType.FIELD:
			var node : LineEdit = get_content() as LineEdit
			node.text = ""
		PanelType.CHECKBOX:
			var node : CheckBox = get_content() as CheckBox
			node.set_pressed(false)
		PanelType.DROPDOWN:
			var node : OptionButton = get_content() as OptionButton
			node.selected = 0
		PanelType.SPINBOX:
			var node : SpinBox = get_content() as SpinBox
			node.value = 0

func save_to_unit_resource(resource_p : UnitResourceDict):
	if (resource_p != null):
		resource_p.set_attribute(attribute_name, get_value())
	
func load_from_unit_resource(resource_p : UnitResourceDict):
	if (resource_p != null):
		var value = resource_p.get_attribute_value(attribute_name)
		if (value != null):
			# this assumes that the type of the attribute is the same in the dictionary and in here
			# this obviously means that if the value type of an attribute changes between versions their units
			# won't be compatible with each other
			set_value(value) 
			return

	reset()

func get_value():
	match type:
		PanelType.FIELD:
			var node : LineEdit = get_content() as LineEdit
			return node.text
		PanelType.CHECKBOX:
			var node : CheckBox = get_content() as CheckBox
			return node.is_pressed()
		PanelType.DROPDOWN:
			var node : OptionButton = get_content() as OptionButton
			var index = node.selected
			return index
		PanelType.SPINBOX:
			var node : SpinBox = get_content() as SpinBox
			node.apply()
			return node.get_line_edit().text as float
			
func set_value(val): 
	match type:
		PanelType.FIELD:
			var node : LineEdit = get_content() as LineEdit
			node.text = val
		PanelType.CHECKBOX:
			var node : CheckBox = get_content() as CheckBox
			node.set_pressed(val)
		PanelType.DROPDOWN:
			var node : OptionButton = get_content() as OptionButton
			node.selected = val
		PanelType.SPINBOX:
			var node : SpinBox = get_content() as SpinBox
			node.value = val

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
			PanelType.FIELD:
				make_field_item()
			PanelType.CHECKBOX:
				make_checkbox_item()
			PanelType.DROPDOWN:
				make_dropdown_item()
			PanelType.SPINBOX:
				make_spinbox_item()

func update_text(): 
	if text.is_empty():
		text = self.name
	get_label().text = text
	self.name = text

func update_dropdown():
	if type == 2:
		var dropdown = get_child(1) as OptionButton
		for i in dropdown.item_count:
			dropdown.remove_item(i)
		for item in items:
			dropdown.add_item(item)
	
# you could very easily make this more modular by making one basic
# "make item" function that then can be called inside each specific
# item type function
func make_field_item():
	var root = get_tree().edited_scene_root
	var label = Label.new()
	var line_edit = LineEdit.new()
	
	self.add_child(label, true)
	self.move_child(label, 0)
	self.add_child(line_edit, true)
	self.move_child(line_edit, 1)

	label.owner = root
	line_edit.owner = root
	
	self.set_anchors_preset(PRESET_HCENTER_WIDE, true)
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	line_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	line_edit.editable = true
	
func make_checkbox_item(): 
	var root = get_tree().edited_scene_root
	var label = Label.new()
	var checkbox = CheckBox.new()
	
	self.add_child(label, true)
	self.move_child(label, 0)
	self.add_child(checkbox, true)
	self.move_child(checkbox, 1)
	
	label.owner = root
	checkbox.owner = root
	
	self.set_anchors_preset(PRESET_HCENTER_WIDE, true)
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	checkbox.size_flags_horizontal = SIZE_EXPAND_FILL
	checkbox.set_disabled(false)
	
func make_dropdown_item():
	var root = get_tree().edited_scene_root
	var label = Label.new()
	var dropdown = OptionButton.new()
	
	self.add_child(label, true)
	self.move_child(label, 0)
	self.add_child(dropdown, true)
	self.move_child(dropdown, 1)
	
	label.owner = root
	dropdown.owner = root
	
	self.set_anchors_preset(PRESET_HCENTER_WIDE, true)
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	dropdown.size_flags_horizontal = SIZE_EXPAND_FILL
	dropdown.set_disabled(false)
	
func make_spinbox_item(): 
	var root = get_tree().edited_scene_root
	var label = Label.new()
	var spinbox = SpinBox.new()
	
	self.add_child(label, true)
	self.move_child(label, 0)
	self.add_child(spinbox, true)
	self.move_child(spinbox, 1)
	
	label.owner = root
	spinbox.owner = root
	
	self.set_anchors_preset(PRESET_HCENTER_WIDE, true)
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	spinbox.size_flags_horizontal = SIZE_EXPAND_FILL

# making this work with child scenes like mentioned above would fix having to do this
func _get_property_list():
	var properties = []
	match type:
		PanelType.FIELD:
			pass
		PanelType.CHECKBOX: 
			pass
		PanelType.DROPDOWN:
			properties.append({
				"name": "items",
				"type": TYPE_ARRAY,
				"hint": PROPERTY_HINT_ARRAY_TYPE,
				"hint_string": "%d/%d:" % [TYPE_STRING, PROPERTY_HINT_NONE]
			})
		PanelType.SPINBOX:
			pass
	return properties
	
func _on_save_to_resource(resource : UnitResourceDict):
	save_to_unit_resource(resource)
	
func _on_load_from_resource(resource : UnitResourceDict):
	load_from_unit_resource(resource)
	
# super super jank but I don't know a better way right now
# some way to do globals would probably be the best way
func find_root_unit_editor():
	var cur_node = self.get_parent()
	while true:
		if cur_node is UnitEditor:
			root_editor = cur_node
		elif cur_node == null:
			break
		cur_node = cur_node.get_parent()

# solely for debugging
func test_parent():
	var parent = self.get_parent()
	while parent != null:
		print("name: " + self.name + ", parent: " + str(parent))
		parent = parent.get_parent()
		
# checks whether the resource flag is on
func resource_flag() -> bool:
	if ((flags & 1) > 0):
		return true
	else:
		return false

# adds itself to the resources if the resource flag is set
func update_resources(resources : Array[String]):
	if (resource_flag()):
		resources.append(attribute_name)
	
func _ready():
	if !Engine.is_editor_hint():
		find_root_unit_editor()
		if root_editor != null:
			root_editor.save_to_resource.connect(save_to_unit_resource)
			root_editor.load_from_resource.connect(load_from_unit_resource)
			root_editor.reset.connect(reset)
			root_editor.update_resources.connect(update_resources)
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE
