class_name LabelCheckbox
extends Control


@onready var _label = $TeamUnitType/HBoxContainer/Label
@onready var _checkbox: CheckBox = $TeamUnitType/HBoxContainer/CheckBox

signal box_checked
signal box_unchecked 


func _ready() -> void:
	_checkbox.toggled.connect(_on_checkbox_toggle)



func set_label_text(text: String) -> void: 
	_label.text = text


func _on_checkbox_toggle(toggle_on: bool) -> void: 
	if toggle_on: 
		box_checked.emit()
	else:
		box_unchecked.emit()

func set_box_on() -> void:
	_checkbox.button_pressed = true
func set_box_off() -> void:
	_checkbox.button_pressed = false
	



#
