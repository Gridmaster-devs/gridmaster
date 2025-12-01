@tool
class_name FileTreePanel
extends PanelContainer

var unit_resources : Array[UnitResourceDict] = []
var units : int = 0

@export var unit_editor : UnitEditor

@onready var tree : Tree = $TopVBox/Tree
@onready var add_button = $TopVBox/Buttons/Add
@onready var remove_button = $TopVBox/Buttons/Remove
var tree_root : TreeItem

func add_unit():
	var item : TreeItem = tree.create_item(null, units)
	units += 1
	item.set_text(0, "Unnamed unit")
	unit_resources.append(UnitResourceDict.new())
	
func add_unit_from_resource(unit_resource : UnitResourceDict):
	var item : TreeItem = tree.create_item(null, units)
	units += 1
	item.set_text(0, "Unnamed unit")
	unit_resources.append(unit_resource)
	
	
func remove_unit():
	var selected = tree.get_selected()
	if (selected != null):
		var index = selected.get_index()
		unit_resources.remove_at(index) # this does not check for out of bounds
		tree_root.remove_child(selected)
		unit_editor.unit_resource_removed()
		
func update_selected_name(new_name : String):
	var selected : TreeItem = tree.get_selected()
	if new_name == "":
		selected.set_text(0, "Unnamed unit")
	else:
		selected.set_text(0, new_name)
	

func new_selection():
	var selected : TreeItem = tree.get_selected()
	var index : int = selected.get_index()
	unit_editor.new_unit_resource(unit_resources[index])
	# print("new resource: " + str(unit_resources[index]))
	

func hello():
	print("hello")

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
