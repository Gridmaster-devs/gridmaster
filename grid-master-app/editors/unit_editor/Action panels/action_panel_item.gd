class_name ActionPanelItem
extends Control

# what type of action is represented
var action_type : Action.Type

# all resources that can be selected
var resources : Array[String]
@onready var panel_type_box : OptionButton = $HBoxContainer/OptionButton
@onready var child_panel_parent : Control = $"Child Panel Parent"
@onready var remove_action_button : Button = $"Remove action"

func update_panel_type(selected : int):
	action_type = selected as Action.Type
	
	for i in child_panel_parent.get_children():
		child_panel_parent.remove_child(i)
		
	match action_type:
		Action.Type.CONSUMEPRODUCE:
			create_consumeproduce_panel()
	

func create_consumeproduce_panel():
	var scene : ConsumeProducePanel = preload("res://editors/unit_editor/Action panels/ConsumeProducePanel.tscn").instantiate()
	child_panel_parent.add_child(scene)
	scene.initiate(resources)
	
func self_destruct():
	queue_free()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	remove_action_button.button_up.connect(self_destruct)
	panel_type_box.item_selected.connect(update_panel_type)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
