class_name ButtonPressedEvent
extends GUIEvent

enum ButtonType {LOAD_GAME, END_TURN}

var button_type : ButtonType
var additional_args : Variant

func _init(type : ButtonType, args : Variant = null):
	button_type = type
	additional_args = args
