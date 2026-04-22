class_name ButtonPressedEvent
extends GUIEvent

enum ButtonType {LOAD_GAME, END_TURN, CONNECT_TO_SERVER, SELECT_TEAM, PLAY_ON_SERVER, UPLOAD_GAME}

var button_type : ButtonType
var additional_args : Variant

func _init(type : ButtonType, args : Variant = null):
	button_type = type
	additional_args = args
