class_name LoadGameGUI
extends GUIScene

@onready var _load_game_button : Button = $LoadGameButton
@onready var _connect_server_button : Button = $ConnectServerButton
@onready var _connection_status_label : Label = $ConnectionStatusLabel

func set_connection_status(status_text: String):
	if _connection_status_label:
		_connection_status_label.text = status_text


func _load_game_button_pressed():
	Global.game_type = Global.GameType.SINGLEPLAYER
	send_gm_signal(ButtonPressedEvent.new(ButtonPressedEvent.ButtonType.LOAD_GAME))


func _connect_server_button_pressed():
	Global.game_type = Global.GameType.MULTIPLAYER
	send_gm_signal(ButtonPressedEvent.new(ButtonPressedEvent.ButtonType.CONNECT_TO_SERVER))


func _ready() -> void:
	_load_game_button.pressed.connect(_load_game_button_pressed)
	_connect_server_button.pressed.connect(_connect_server_button_pressed)


func initialize(_args : Variant) -> void:
	pass
