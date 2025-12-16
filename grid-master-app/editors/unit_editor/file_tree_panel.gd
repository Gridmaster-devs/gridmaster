class_name FileTreePanel
extends PanelContainer

# This class handles the tree displaying the units, and also contains
# the unit resource objects itself, as that was the cleanest way to do this
# This does require there to be some indirect calls with the unit editor relaying
# the information / signal / function call forward to its children

var unit_resources : Array[UnitResourceDict] = []
var units : int = 0

var unit_editor : UnitEditor

@onready var tree : Tree = $TopVBox/Tree
@onready var add_button = $TopVBox/Buttons/Add
@onready var remove_button = $TopVBox/Buttons/Remove
var tree_root : TreeItem


func reset_units():
	units = 0
	unit_resources.clear()
	for child in tree_root.get_children():
		tree_root.remove_child(child)
	
	unit_editor.unit_resource_removed()

# adds a new unit to the tree and to the unit array
func add_unit():
	var item : TreeItem = tree.create_item(null, units)
	units += 1
	item.set_text(0, "Unnamed unit")
	unit_resources.append(UnitResourceDict.new())


# only called when a unit is loaded from a file
func add_unit_from_resource(unit_resource : UnitResourceDict):
	var item : TreeItem = tree.create_item(null, units)
	units += 1
	var unit_name = unit_resource.get_attribute_value("name")
	if (unit_name == null or unit_name == ""):
		item.set_text(0, "Unnamed unit")
	else:
		item.set_text(0, unit_name)
	unit_resources.append(unit_resource)
	

# removes a unit from the tree and the array
func remove_unit():
	var selected : TreeItem = tree.get_selected()
	if (selected != null):
		var index = selected.get_index()
		unit_resources.remove_at(index) # this does not check for out of bounds
		tree_root.remove_child(selected)
		unit_editor.unit_resource_removed()


# called by the unit editor when the user changes the unit's name
func update_selected_name(new_name : String):
	var selected : TreeItem = tree.get_selected()
	if new_name == "":
		selected.set_text(0, "Unnamed unit")
	else:
		selected.set_text(0, new_name)
	

# called when the user clicks on a new item in the tree
func new_selection():
	var selected : TreeItem = tree.get_selected()
	var index : int = selected.get_index()
	unit_editor.new_unit_resource(unit_resources[index])

	
# called once by the unit editor at the start of the program
func link_unit_editor(ue : UnitEditor):
	unit_editor = ue


func get_units() -> Array[UnitResourceDict]:
	return unit_resources
	

func set_units(units_p : Array[UnitResourceDict]):
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


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
