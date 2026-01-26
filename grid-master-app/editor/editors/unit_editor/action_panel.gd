class_name ActionPanel
extends PanelContainer

# the attributes that are labeled 'resource'
# these are used in the consume / produce action dropdown menu
var resources : Array[String]
var unit_editor : UnitEditor

# signal for all the action panel items to save their action into a single array to be put into a resource
signal save_to_action_array(resources : Array[Action])

# where all the action panel items go
@onready var actions_box : VBoxContainer = $VBoxContainer/ScrollContainer/Actions
@onready var add_action_button : Button = $"VBoxContainer/Add action"

func reset_children():
	for child in actions_box.get_children():
		child.self_destruct()

# called once at the initialization of the user interface
# in case the user can at some point add their own resources at runtime, this will need to be called again
# to update the resource list
func update_resource_array(new_resources : Array[String]):
	resources = new_resources

func add_action():
	var scene : ActionPanelItem = preload("res://editor/editors/unit_editor/Action panels/ActionPanelItem.tscn").instantiate()
	scene.initiate(resources, save_to_action_array)
	actions_box.add_child(scene)

# solely for loading from a resource
func add_action_from_resource(action : Action):
	var scene : ActionPanelItem = preload("res://editor/editors/unit_editor/Action panels/ActionPanelItem.tscn").instantiate()
	scene.initiate(resources, save_to_action_array)
	actions_box.add_child(scene)
	scene.load_from_action(action)
	
func save_to_resource(unit_resource : UnitResourceDict):
	if (unit_resource != null):
		var action_array : Array[Action] = []
		save_to_action_array.emit(action_array)
		unit_resource.save_actions(action_array)
	
func load_from_resource(unit_resource : UnitResourceDict):
	
	reset_children()
	
	if (unit_resource == null):
		return
		
	var action_array = unit_resource.load_actions()
	if (action_array == null):
		return
		
	for action in action_array:
		add_action_from_resource(action)
	
# called once by the unit editor at the start of the program
# any stuff that should be called at the start of the program but only after the unit editor is ready
# should go here
func link_unit_editor(ue : UnitEditor):
	unit_editor = ue
	unit_editor.save_to_resource.connect(save_to_resource)
	unit_editor.load_from_resource.connect(load_from_resource)
	unit_editor.reset.connect(reset_children)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_action_button.button_up.connect(add_action)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
