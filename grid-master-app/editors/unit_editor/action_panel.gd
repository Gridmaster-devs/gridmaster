class_name ActionPanel
extends PanelContainer

var resources : Array[String]
@onready var actions_box : VBoxContainer = $VBoxContainer/ScrollContainer/Actions
@onready var add_action_button : Button = $"VBoxContainer/Add action"


func add_action():
	var scene = preload("res://editors/unit_editor/Action panels/action_panel_item.tscn").instantiate()
	actions_box.add_child(scene)
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_action_button.button_up.connect(add_action)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
