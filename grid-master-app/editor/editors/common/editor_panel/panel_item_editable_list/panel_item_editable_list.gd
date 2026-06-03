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
## }

signal chosen_item_added(chosen_option_id: int)
signal chosen_item_removed(chosen_option_id: int)

@onready var add_button = $AddContainer/AddButton
@onready var drop_down = $AddContainer/DropDown

@export var options_list_provider: Node
@export var label_text: String : 
	set(new_text):
		self.get_children()[0].text = new_text

## The list of options available in the drop-down
var options_list: Array[Variant]
## The list of options chosen by clicking the add button
var chosen_list: Dictionary[int, Variant]

func options_changed():
	drop_down.clear()
	for option in options_list:
		drop_down.add_item(option.name, option.id)
	# NOTE sub-optimal but works for now
	for chosen_option in chosen_list.values():
		var found = false
		for option in options_list:
			if option.id == chosen_option.id:
				found = true
		if !found:
			_remove_chosen(chosen_option.id)

func _remove_chosen(id: int):
	#FIXME this is kind of unsafe
	for hbox in self.get_children().slice(2):
		if hbox.get_children()[1].id == id:
			hbox.queue_free()
			break
	chosen_list.erase(id)
	chosen_item_removed.emit(id)
	
	
func _chosen_item_added():
	if drop_down.selected != -1:
		var chosen_option = null
		# find chosen option in options_list
		for option in options_list:
			if option.id == drop_down.selected:
				chosen_option = option
		# check that option isn't already added to chosen list
		if chosen_option != null and chosen_list.get(chosen_option.id) != null:
			chosen_option = null
		# if chosen option in option list but not already in chosen list then add it to chosen
		if chosen_option != null:
			chosen_list[chosen_option.id] = chosen_option
			
			var hbox = HBoxContainer.new()
			
			var unit_name_label = Label.new()
			unit_name_label.text = chosen_option.name
			
			var remove_chosen_item_button = PanelItemEditableListButton.new(chosen_option.id)
			remove_chosen_item_button.text = "x"
			remove_chosen_item_button.pressed_with_id.connect(_chosen_item_removed)
			
			self.add_child(hbox)
			hbox.add_child(unit_name_label)
			hbox.add_child(remove_chosen_item_button)
			
			chosen_item_added.emit(chosen_option.id)
	
func _chosen_item_removed(id: int):
	_remove_chosen(id)
	
func _on_visibility_changed(is_hidden: bool):
	self.visible = is_hidden

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	options_list = options_list_provider.state
	add_button.pressed.connect(_chosen_item_added)
	return
