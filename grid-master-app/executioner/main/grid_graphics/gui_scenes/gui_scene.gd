@abstract
class_name GUIScene
extends Control

var scene_tree : SceneTree

func send_gm_signal(event : StateMachineEvent):
	scene_tree.call_group(GameMaster.GROUP_NAME, GameMaster.EVENT_INPUT_FUNC_NAME, event)

func _ready() -> void:
	scene_tree = get_tree()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_custom_ready()


@abstract
func initialize(args : Variant) -> void

@abstract
func _custom_ready() -> void
