class_name ActionPanel
extends PanelContainer

var resources : Array[String]
signal save_to_action_array(resources : Array[Action])
@onready var actions_box : VBoxContainer = $VBoxContainer/ScrollContainer/Actions
@onready var add_action_button : Button = $"VBoxContainer/Add action"


func reset_children():
	for child in actions_box.get_children():
		child.self_destruct()

func update_resource_array(new_resources : Array[String]):
	resources = new_resources

func add_action():
	var scene : ActionPanelItem = preload("res://editors/unit_editor/Action panels/action_panel_item.tscn").instantiate()
	scene.initiate(resources, save_to_action_array)
	actions_box.add_child(scene)
	
func add_action_from_resource(action : Action):
	var scene : ActionPanelItem = preload("res://editors/unit_editor/Action panels/action_panel_item.tscn").instantiate()
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
		
func add_resource_saveload_signals(save_r : Signal, load_r : Signal):
	save_r.connect(save_to_resource)
	load_r.connect(load_from_resource)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_action_button.button_up.connect(add_action)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
