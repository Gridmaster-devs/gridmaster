class_name FileTreePanel
extends PanelContainer

# This class handles the tree displaying the units, and also contains
# the unit resource objects itself, as that was the cleanest way to do this
# This does require there to be some indirect calls with the unit editor relaying
# the information / signal / function call forward to its children

signal units_changed

var unit_resources : Array[UnitResource] = []
var units : int = 0

var unit_editor : UnitEditor

@onready var tree : Tree = $TopVBox/Tree
@onready var add_button = $TopVBox/Buttons/Add
@onready var remove_button = $TopVBox/Buttons/Remove
var tree_root : TreeItem

var state = unit_resources

func add_to_tree(unit: UnitResource):
	var item : TreeItem = tree.create_item(null, units)
	item.set_text(0, "Unnamed unit")
	units += 1
	
func remove_selected_from_tree():
	var selected : TreeItem = tree.get_selected()
	var index = null
	if (selected != null):
		index = selected.get_index()
		tree_root.remove_child(selected)
		units -= 1
	return index


func reset_units():
	units = 0
	#tree_id_to_unit_resource_id = {}
	unit_resources.clear()
	for child in tree_root.get_children():
		tree_root.remove_child(child)
	
	# TODO clean up the signals between file tree panel and unit editor, might be enough to use the 
	# single units_changed instead of a mix of multiple signals and direct function calls i.e.
	# remove messy coupling
	unit_editor.unit_resource_removed()
	units_changed.emit()

# adds a new unit to the tree and to the unit array
func add_unit():
	unit_editor.save_to_resource.emit(unit_editor.unit_resource)
	var new_unit_resource = _new_unit_with_unused_id(_reserved_ids(unit_resources))
	unit_resources.append(new_unit_resource)
	
	
	add_to_tree(new_unit_resource)
	
	units_changed.emit()


# only called when a unit is loaded from a file
func add_unit_from_resource(unit_resource : UnitResource) -> bool:
	if unit_resource.get_attribute_value("id") == null:
		unit_editor.save_to_resource.emit(unit_editor.unit_resource)
		var all_units: Array[UnitResource] = unit_resources.duplicate()
		all_units.append(unit_resource)
		unit_resource.set_attribute("id", _new_unit_with_unused_id(_reserved_ids(all_units)).id)
	else:
		for existing in unit_resources:
			if existing.id == unit_resource.id:
				_show_duplicate_id_error(unit_resource.id)
				return false
	var item : TreeItem = tree.create_item(null, units)
	
	var unit_name = unit_resource.get_attribute_value("name")
	
	if (unit_name == null or unit_name == ""):
		item.set_text(0, "Unnamed unit")
	else:
		item.set_text(0, unit_name)
		
	unit_resources.append(unit_resource)
	
	#tree_id_to_unit_resource_id[units] = unit_resource.id
	units += 1
	
	units_changed.emit()
	return true


# removes a unit from the tree and the array
func remove_unit():
	var index = remove_selected_from_tree()
	if index != null:
		var deleted_id: int = unit_resources[index].id
		unit_resources.remove_at(index) # this does not check for out of bounds
		for unit in unit_resources:
			var saved_ids: Variant = unit.get_attribute_value("producible_units")
			if saved_ids is Array and deleted_id in saved_ids:
				unit.set_attribute("producible_units", saved_ids.filter(func(id: Variant) -> bool: return id != deleted_id))
		unit_editor.unit_resource_removed()
		units_changed.emit()


# called by the unit editor when the user changes the unit's name
func update_selected_name(new_name : String):
	var selected : TreeItem = tree.get_selected()
	var selected_index = selected.get_index()
	if new_name == "":
		selected.set_text(0, "Unnamed unit")
	else:
		selected.set_text(0, new_name)
		unit_resources[selected_index].set_attribute("name", new_name)
	units_changed.emit()
	

# called when the user clicks on a new item in the tree
func new_selection():
	var selected : TreeItem = tree.get_selected()
	var index : int = selected.get_index()
	unit_editor.new_unit_resource(unit_resources[index])

	
# called once by the unit editor at the start of the program
func link_unit_editor(ue : UnitEditor):
	unit_editor = ue


func get_units() -> Array[UnitResource]:
	return unit_resources
	

func set_units(units_p : Array[UnitResource]) -> bool:
	var ids: Array[int] = []
	for unit in units_p:
		if unit.get_attribute_value("id") == null:
			continue
		if unit.id in ids:
			_show_duplicate_id_error(unit.id)
			return false
		ids.append(unit.id)
	var reserved_ids := _reserved_ids(units_p)
	for unit in units_p:
		if unit.get_attribute_value("id") == null:
			var id := _new_unit_with_unused_id(reserved_ids).id
			unit.set_attribute("id", id)
			reserved_ids.append(id)
	reset_units()
	for unit in units_p:
		add_unit_from_resource(unit)
	return true


func _reserved_ids(resources: Array[UnitResource]) -> Array:
	var ids: Array = []
	for unit in resources:
		if unit.get_attribute_value("id") != null:
			ids.append(unit.id)
		var saved_ids: Variant = unit.get_attribute_value("producible_units")
		if saved_ids is Array:
			ids.append_array(saved_ids)
	return ids


func _new_unit_with_unused_id(reserved_ids: Array) -> UnitResource:
	var unit := UnitResource.new()
	while unit.id in reserved_ids:
		unit = UnitResource.new()
	return unit


func _show_duplicate_id_error(id: int) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Duplicate unit ID"
	dialog.dialog_text = "Cannot import units: ID %d already exists. Change the duplicate ID in the source file and try again." % id
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	TooltipHelper.apply(tree, "unit", "unit_list")
	TooltipHelper.apply(add_button, "unit", "add_unit")
	TooltipHelper.apply(remove_button, "unit", "remove_unit")
	tree_root = tree.create_item(null, 0)
	tree.hide_root = true
	tree.item_selected.connect(new_selection)
	
	add_button.button_up.connect(add_unit)
	remove_button.button_up.connect(remove_unit)
