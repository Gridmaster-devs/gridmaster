class_name InGameDefaultGUI
extends GUIScene

@onready var _game_name_label : Label = $GameNameLabel
@onready var _end_turn_button : GUIButton = $EndTurnButton
@onready var message_window_node: MessageWindow = $MessageWindow

func _ready():
	_end_turn_button.pressed.connect(_end_turn_button_pressed)

func _end_turn_button_pressed() -> void:
	send_gm_signal(ButtonPressedEvent.new(ButtonPressedEvent.ButtonType.END_TURN))

func set_waiting() -> void:
	_end_turn_button.text = "Waiting for others..."
	_end_turn_button.disabled = true

func set_turn_active() -> void:
	_end_turn_button.text = "End Turn"
	_end_turn_button.disabled = false

# Normal _init() does not work when you are instantiating
# a scene from a file
func initialize(game_name : Variant) -> void:
	_game_name_label.text = game_name as String
