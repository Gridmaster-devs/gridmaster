extends Control
class_name UnitInformationItem

@onready var _label = $HBoxContainer/Label
@onready var _data = $HBoxContainer/Label2




func set_information(label: String, data: String) -> void: 
	_label.text = label
	_data.text = data
