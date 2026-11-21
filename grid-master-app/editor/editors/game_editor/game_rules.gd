extends Control
class_name GameRules


@onready var _combat_speed_ui: LineEdit = $"EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Combat speed/LineEdit"
@onready var _resources_box: VBoxContainer = $"EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Resources"

#constants
const MAX_RESOURCES = 10
const RESOURCE_ICON_SIZE = Vector2(32, 32)

var _rules: Dictionary[String, Variant] = {}
var _rule_uis: Dictionary[String, LineEdit] = {}
var _resource_name_uis: Array[LineEdit] = []
var _resource_icon_uis: Array[TextureRect] = []

signal rules_changed(rules: Dictionary[String, Variant])
signal resources_changed(resources: Array[String])


func _ready() -> void:
	#combat speed
	_combat_speed_ui.text_changed.connect(_integer_rule_changed.bind("combat_rounds"))
	_rule_uis["combat_rounds"] = _combat_speed_ui
	#resources
	_init_resource_uis()

#adds a name field and an icon for each resource slot. Empty slots are shown as None
func _init_resource_uis() -> void:
	for i in range(MAX_RESOURCES):
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = "Resource %d" % (i + 1)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_line := LineEdit.new()
		name_line.placeholder_text = ConsumeProduce.NO_RESOURCE
		name_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_line.text_changed.connect(_on_resource_name_changed)
		var icon_rect := TextureRect.new()
		icon_rect.custom_minimum_size = RESOURCE_ICON_SIZE
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var choose_icon_button := Button.new()
		choose_icon_button.text = "Choose icon"
		choose_icon_button.pressed.connect(_open_resource_icon_picker.bind(i))
		var clear_icon_button := Button.new()
		clear_icon_button.text = "Clear"
		clear_icon_button.pressed.connect(_on_resource_icon_saved.bind(null, i))
		row.add_child(label)
		row.add_child(name_line)
		row.add_child(icon_rect)
		row.add_child(choose_icon_button)
		row.add_child(clear_icon_button)
		_resources_box.add_child(row)
		_resource_name_uis.append(name_line)
		_resource_icon_uis.append(icon_rect)



##signal response
func _rule_changed(rule_value: Variant, rule_id: String) -> void:
	_rules[rule_id] = rule_value
	rules_changed.emit(_rules)
	
func _integer_rule_changed(raw_rule_value: String, rule_id: String) -> void:
	_rules[rule_id] = int(raw_rule_value)
	rules_changed.emit(_rules)

func _on_resource_name_changed(_new_name: String) -> void:
	resources_changed.emit(get_resources())

#opens the same drag and drop image popup that the map editor uses
func _open_resource_icon_picker(slot: int) -> void:
	var drag_n_drop: ImageDragAndDropPopup = preload("res://common/popups/image_drag_and_drop.tscn").instantiate()
	drag_n_drop.add_to_tree()
	drag_n_drop.texture_saved.connect(_on_resource_icon_saved.bind(slot))

func _on_resource_icon_saved(texture: Texture2D, slot: int) -> void:
	_resource_icon_uis[slot].texture = texture

func get_rules() -> Dictionary[String, Variant]: 
	return _rules

func import(new_rules: Dictionary[String, Variant]) -> void: 
	_rules = new_rules
	for rule in _rules.keys(): 
		if _rule_uis.has(rule):
			_rule_uis[rule].text = str(_rules[rule])
	rules_changed.emit(_rules)

## Returns the names of the defined resources. Empty (None) slots and duplicates are skipped.
func get_resources() -> Array[String]:
	var out: Array[String] = []
	for name_line in _resource_name_uis:
		var resource_name := name_line.text.strip_edges()
		if resource_name == "" or resource_name == ConsumeProduce.NO_RESOURCE or out.has(resource_name):
			continue
		out.append(resource_name)
	return out

## Returns the icons of the defined resources by name. Resources without an icon are skipped.
func get_resource_icons() -> Dictionary[String, Texture2D]:
	var out: Dictionary[String, Texture2D] = {}
	var resources := get_resources()
	for i in range(_resource_name_uis.size()):
		var resource_name := _resource_name_uis[i].text.strip_edges()
		var icon: Texture2D = _resource_icon_uis[i].texture
		if resources.has(resource_name) and not out.has(resource_name) and icon != null:
			out[resource_name] = icon
	return out

## Fills the resource slots in order. Slots without a resource are left as None.
## Games made before resource icons existed have no icons.
func import_resources(new_resources: Array[String], new_icons: Dictionary[String, Texture2D] = {}) -> void:
	for i in range(_resource_name_uis.size()):
		if i < new_resources.size():
			_resource_name_uis[i].text = new_resources[i]
			_resource_icon_uis[i].texture = new_icons.get(new_resources[i], null)
		else:
			_resource_name_uis[i].text = ""
			_resource_icon_uis[i].texture = null
	resources_changed.emit(get_resources())





#
