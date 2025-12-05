class_name ActionPanelItem
extends Control

# IMPORTANT NOTE!!!!!!!
# every child item MUST have the methods save_to_action and load_from_action

# what type of action is represented
var action_type : Action.Type

# all resources that can be selected
var resources : Array[String]
@onready var panel_type_box : OptionButton = $HBoxContainer/OptionButton
@onready var child_panel_parent : Control = $"Child Panel Parent"
@onready var remove_action_button : Button = $"Remove action"
@onready var action_name_line : LineEdit = $"Action name"
var child_panel : Node

func reset_children():
	child_panel = null
	for i in child_panel_parent.get_children():
		child_panel_parent.remove_child(i)

func update_panel_type(selected : int):
	action_type = selected as Action.Type
	reset_children()
	
	match action_type:
		Action.Type.CONSUMEPRODUCE:
			create_consumeproduce_panel()
			

	

func create_consumeproduce_panel():
	var scene : ConsumeProducePanel = preload("res://editors/unit_editor/Action panels/ConsumeProducePanel.tscn").instantiate()
	child_panel_parent.add_child(scene)
	scene.initiate(resources)
	child_panel = scene
	
func self_destruct():
	queue_free()
	
func save_action_to_array(action_array : Array[Action]):
	var action : Action
	if (child_panel != null):
		action = child_panel.save_to_action()
	else:
		action = NoneAction.new()
		action.action_type = Action.Type.NONE
		
	action.action_name = action_name_line.text # I don't think this can ever be null?
	action_array.append(action)
		
func load_from_action(action : Action):
	if (action != null):
		action_name_line.text = action.action_name
		if action is ConsumeProduce:
			update_panel_type(Action.Type.CONSUMEPRODUCE as int)
			panel_type_box.select(Action.Type.CONSUMEPRODUCE as int)
			child_panel.load_from_action(action)
			
		if action is NoneAction:
			update_panel_type(Action.Type.NONE as int)
			panel_type_box.select(Action.Type.NONE as int)
			
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	remove_action_button.button_up.connect(self_destruct)
	panel_type_box.item_selected.connect(update_panel_type)

func initiate(resource_array : Array[String], save_action : Signal):
	save_action.connect(save_action_to_array)
	resources = resource_array

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
