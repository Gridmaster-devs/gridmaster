class_name LoadGameGUI
extends GUIScene

@onready var _load_game_button : Button = $LoadGameButton
@onready var _connect_server_button : Button = $ConnectServerButton


func _load_game_button_pressed():
	send_gm_signal(ButtonPressedEvent.new(ButtonPressedEvent.ButtonType.LOAD_GAME))


func _connect_server_button_pressed():
	send_gm_signal(ButtonPressedEvent.new(ButtonPressedEvent.ButtonType.CONNECT_TO_SERVER))


func _ready() -> void:
	_load_game_button.pressed.connect(_load_game_button_pressed)
	_connect_server_button.pressed.connect(_connect_server_button_pressed)


func initialize(_args : Variant) -> void:
	pass

