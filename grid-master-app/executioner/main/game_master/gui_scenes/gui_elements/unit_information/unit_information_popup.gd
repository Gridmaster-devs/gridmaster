class_name UnitInformationPopup
extends PopupWindow


@onready var _contents = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox


var _data_information_item_map: Dictionary[String, UnitInformationItem]

@onready var unit_info_item = preload("res://executioner/main/game_master/gui_scenes/gui_elements/unit_information/unit_information_item.tscn")
@onready var production_control_item = preload("res://executioner/main/game_master/gui_scenes/gui_elements/unit_information/production_control_item.tscn")

func _init() -> void: 
	super.set_popup_name("unit information popup")
	super.set_unblocking()



func set_unit_info(unit: Unit, game_data_manager: GameDataManager) -> void: 
	# Add the unit name first
	var name_item: UnitInformationItem = unit_info_item.instantiate()
	_contents.add_child(name_item)
	name_item.set_information("Name", unit.get_unit_name())
	_data_information_item_map["Name"] = name_item
	
	var unit_type_attribute_names = unit.type.attribute_conversion_table.keys()
	
	#CAUTION FIXME dumbass hack to get dynamic hp and morale
	for attribute_name in unit_type_attribute_names:
		if attribute_name == "health":
			var attribute_value = unit.hp
			var information_item: UnitInformationItem = unit_info_item.instantiate()
			_contents.add_child(information_item)
			information_item.set_information(attribute_name, str(attribute_value))
			_data_information_item_map[attribute_name] = information_item
		elif attribute_name == "morale":
			var attribute_value = unit.morale
			var information_item: UnitInformationItem = unit_info_item.instantiate()
			_contents.add_child(information_item)
			information_item.set_information(attribute_name, str(attribute_value))
			_data_information_item_map[attribute_name] = information_item
		else:
			var attribute_key = unit.type.attribute_conversion_table[attribute_name]
			var attribute_value = unit.type.attributes[attribute_key]
			var information_item: UnitInformationItem = unit_info_item.instantiate()
			_contents.add_child(information_item)
			information_item.set_information(attribute_name, str(attribute_value))
			_data_information_item_map[attribute_name] = information_item
	
	# Add the production_control_item if the unit is a production unit
	if unit.type.is_production_unit and unit.current_action == null:
		var item: ProductionControlItem = production_control_item.instantiate()
		_contents.add_child(item)
		item.custom_minimum_size = Vector2(0, 100)
		item.setup(unit, game_data_manager)
		item.production_selected.connect(_on_production_selected)

func _on_production_selected():
	hide()
