class_name UnitInformationPopup
extends PopupWindow


@onready var _contents = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox


var _data_information_item_map: Dictionary[String, UnitInformationItem]

func _init() -> void: 
	super.set_popup_name("unit information popup")
	super.set_unblocking()



func set_unit_info(unit: Unit) -> void: 
	var unit_type_attribute_names = unit.type.attribute_conversion_table.keys()
	for attribute_name in unit_type_attribute_names:
		var attribute_key = unit.type.attribute_conversion_table[attribute_name]
		var attribute_value = unit.type.attributes[attribute_key]
		var information_item: UnitInformationItem = preload("res://executioner/main/game_master/gui_scenes/gui_elements/unit_information/unit_information_item.tscn").instantiate()
		_contents.add_child(information_item)
		information_item.set_information(attribute_name, str(attribute_value))
		_data_information_item_map[attribute_name] = information_item
