extends Control
class_name GameRules


@onready var _combat_speed_ui: LineEdit = $"EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Combat speed/LineEdit"
@onready var _resources_box: VBoxContainer = $"EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Resources"

#constants
const MAX_RESOURCES = 10

var _rules: Dictionary[String, Variant] = {}
var _rule_uis: Dictionary[String, LineEdit] = {}
var _resource_name_uis: Array[LineEdit] = []

signal rules_changed(rules: Dictionary[String, Variant])
signal resources_changed(resources: Array[String])


func _ready() -> void:
	#combat speed
	_combat_speed_ui.text_changed.connect(_integer_rule_changed.bind("combat_rounds"))
	_rule_uis["combat_rounds"] = _combat_speed_ui
	#resources
	_init_resource_uis()

#adds a name field for each resource slot. Empty slots are shown as None
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
		row.add_child(label)
		row.add_child(name_line)
		_resources_box.add_child(row)
		_resource_name_uis.append(name_line)



##signal response
func _rule_changed(rule_value: Variant, rule_id: String) -> void:
	_rules[rule_id] = rule_value
	rules_changed.emit(_rules)
	
func _integer_rule_changed(raw_rule_value: String, rule_id: String) -> void:
	_rules[rule_id] = int(raw_rule_value)
	rules_changed.emit(_rules)

func _on_resource_name_changed(_new_name: String) -> void:
	resources_changed.emit(get_resources())

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

## Fills the resource slots in order. Slots without a resource are left as None.
func import_resources(new_resources: Array[String]) -> void:
	for i in range(_resource_name_uis.size()):
		if i < new_resources.size():
			_resource_name_uis[i].text = new_resources[i]
		else:
			_resource_name_uis[i].text = ""
	resources_changed.emit(get_resources())





#
