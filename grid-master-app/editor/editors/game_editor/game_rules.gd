extends Control
class_name GameRules


@onready var _combat_speed_ui: LineEdit = $"EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Combat speed/LineEdit"

var _rules: Dictionary[String, Variant] = {}
var _rule_uis: Dictionary[String, LineEdit] = {}

signal rules_changed(rules: Dictionary[String, Variant])


func _ready() -> void: 
	#combat speed
	_combat_speed_ui.text_changed.connect(_rule_changed.bind("combat_rounds"))
	_rule_uis["combat_rounds"] = _combat_speed_ui


#signal response
func _rule_changed(rule_value: Variant, rule: String) -> void:
	_rules[rule] = rule_value
	rules_changed.emit(_rules)


func get_rules() -> Dictionary[String, Variant]: 
	return _rules

func import(new_rules: Dictionary[String, Variant]) -> void: 
	_rules = new_rules
	for rule in _rules.keys(): 
		if _rule_uis.has(rule):
			_rule_uis[rule].text = str(_rules[rule])
	rules_changed.emit(_rules)





#
