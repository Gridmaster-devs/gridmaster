class_name FileTreePanel
extends PanelContainer

# This class handles the tree displaying the units, and also contains
# the unit resource objects itself, as that was the cleanest way to do this
# This does require there to be some indirect calls with the unit editor relaying
# the information / signal / function call forward to its children

signal units_changed

var unit_resources : Array[UnitResource] = []
#var tree_id_to_unit_resource_id: Dictionary[int, int]
var units : int = 0

var unit_editor : UnitEditor

@onready var tree : Tree = $TopVBox/Tree
@onready var add_button = $TopVBox/Buttons/Add
@onready var remove_button = $TopVBox/Buttons/Remove
var tree_root : TreeItem

var state = unit_resources

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
	var item : TreeItem = tree.create_item(null, units)
	item.set_text(0, "Unnamed unit")
	
	var new_unit_resource = UnitResource.new()
	unit_resources.append(new_unit_resource)
	
	#tree_id_to_unit_resource_id[units] = new_unit_resource.id
	units += 1
	units_changed.emit()


# only called when a unit is loaded from a file
func add_unit_from_resource(unit_resource : UnitResource):
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


# removes a unit from the tree and the array
func remove_unit():
	var selected : TreeItem = tree.get_selected()
	if (selected != null):
		var index = selected.get_index()
		unit_resources.remove_at(index) # this does not check for out of bounds
		tree_root.remove_child(selected)
		
		#tree_id_to_unit_resource_id.erase(index)
		units -= 1
		
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
	

func set_units(units_p : Array[UnitResource]):
	reset_units()
	for unit in units_p:
		add_unit_from_resource(unit)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tree_root = tree.create_item(null, 0)
	tree.hide_root = true
	tree.item_selected.connect(new_selection)
	
	add_button.button_up.connect(add_unit)
	remove_button.button_up.connect(remove_unit)
