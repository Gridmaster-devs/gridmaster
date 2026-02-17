@abstract
class_name GUIScene
extends Control

var scene_tree : SceneTree = get_tree()

func send_gm_signal(event : StateMachineEvent):
	scene_tree.call_group(GameMaster.GROUP_NAME, GameMaster.EVENT_INPUT_FUNC_NAME, event)
