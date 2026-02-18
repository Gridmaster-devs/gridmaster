class_name InGameDefaultGUI
extends GUIScene

@onready var _game_name_label : Label = $GameNameLabel
@onready var _end_turn_button : GUIButton = $EndTurnButton


func _end_turn_button_pressed() -> void:
	send_gm_signal(ButtonPressedEvent.new(ButtonPressedEvent.ButtonType.END_TURN))


# Normal _init() does not work when you are instantiating
# a scene from a file
func initialize(game_name : Variant) -> void:
	_game_name_label.text = game_name as String
	

func _custom_ready() -> void:
	_end_turn_button.pressed.connect(_end_turn_button_pressed)
