@abstract
class_name GUIScene
extends Node

func send_gm_signal(event : StateMachineEvent):
	get_tree().call_group(GameMaster.GROUP_NAME, GameMaster.EVENT_INPUT_FUNC_NAME, event)


@abstract
func initialize(args : Variant) -> void
