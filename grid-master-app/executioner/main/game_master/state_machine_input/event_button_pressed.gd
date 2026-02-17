class_name ButtonPressedEvent
extends GUIEvent

enum ButtonType {LOAD_GAME_BUTTON}

var button_id : ButtonType = ButtonType.LOAD_GAME_BUTTON
var additional_args : Variant

func _init(id : ButtonType, args : Variant = null):
	button_id = id
	additional_args = args
