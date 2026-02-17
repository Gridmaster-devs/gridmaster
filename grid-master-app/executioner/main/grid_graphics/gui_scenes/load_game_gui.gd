class_name LoadGameGUI
extends GUIScene

@onready var _load_game_button : Button = $LoadGameButton


func _load_game_button_pressed():
	send_gm_signal(ButtonPressedEvent.new(ButtonPressedEvent.ButtonType.LOAD_GAME_BUTTON))


func _init() -> void:
	_load_game_button.pressed.connect(_load_game_button_pressed)
