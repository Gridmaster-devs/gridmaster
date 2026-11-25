class_name PanelItemEditableList
extends VBoxContainer

## Assumes option_list_provider has interface:
## {
##		state: Array[Variant]
## }
## where the type inside the array is the option.

## Assumes below interface for options:
## {
##		name: string
## 		id: int
##		is_producible_unit: bool
## }

## WARNING: This was supposed to be a more general purpose component but now relies on an interface specific to UnitType. 

@onready var add_button: Button = $AddContainer/AddButton
@onready var drop_down: OptionButton = $AddContainer/DropDown

@export var options_list_provider: Node
@export var label_text: String : 
	set(new_text):
		self.get_children()[0].text = new_text
@export var attribute_name: String

## The list of options available in the drop-down
var options_list: Array[Variant]
## Saved selections, including target IDs that may be imported later.
var chosen_list: Array[int]
var _chosen_rows: Dictionary[int, HBoxContainer] = {}

# Called when the node enters the scene tree for the first time.


func _ready() -> void:
	TooltipHelper.apply(get_child(0), "unit", "producible_units")
	TooltipHelper.apply(add_button, "unit", "producible_units_add")
	options_list = options_list_provider.state
	add_button.pressed.connect(_chosen_item_added)
	return


func options_changed() -> void:
	drop_down.clear()
	var disabled_ids: Array[int] = []
	for option in options_list:
		if option.get_attribute_value("is_producible_unit") == true:
			drop_down.add_item(option.name, option.id)
		else:
			disabled_ids.append(option.id)
	var eligible_choices: Array[int] = chosen_list.filter(func(id: int) -> bool: return id not in disabled_ids)
	_reset_chosen()
	for id in eligible_choices:
		add_chosen(id)


func _remove_chosen(id: int) -> void:
	chosen_list.erase(id)
	if _chosen_rows.has(id):
		var row: HBoxContainer = _chosen_rows[id]
		_chosen_rows.erase(id)
		remove_child(row)
		row.queue_free()
	


func _reset_chosen() -> void:
	for row in _chosen_rows.values():
		remove_child(row)
		row.queue_free()
	_chosen_rows.clear()
	chosen_list.clear()


func add_chosen(id: int) -> void:
	if chosen_list.has(id):
		return
	chosen_list.append(id)
	var index: int = drop_down.get_item_index(id)
	if index == -1:
		return

	var hbox := HBoxContainer.new()
	var unit_name_label := Label.new()
	unit_name_label.text = drop_down.get_item_text(index)
	var remove_chosen_item_button := PanelItemEditableListButton.new(id)
	remove_chosen_item_button.text = "x"
	TooltipHelper.apply(remove_chosen_item_button, "unit", "producible_units_remove")
	remove_chosen_item_button.pressed_with_id.connect(_remove_chosen)
	hbox.add_child(unit_name_label)
	hbox.add_child(remove_chosen_item_button)
	_chosen_rows[id] = hbox
	add_child(hbox)
	


func _chosen_item_added() -> void:
	if drop_down.selected != -1:
		add_chosen(drop_down.get_selected_id())

	


func _save_to_unit_resource(resource_p : UnitResource) -> void:
	if (resource_p != null):
		resource_p.set_attribute(attribute_name, chosen_list.duplicate())
		


func _load_from_unit_resource(resource_p : UnitResource) -> void:
	if (resource_p != null):
		var value: Variant = resource_p.get_attribute_value(attribute_name)
		if (value != null):
			# this assumes that the type of the attribute is the same in the dictionary and in here
			# this obviously means that if the value type of an attribute changes between versions their units
			# won't be compatible with each other
			_reset_chosen()
			for unit_type_id in value:
				if unit_type_id is int:
					add_chosen(unit_type_id)
			return
	_reset_chosen()
