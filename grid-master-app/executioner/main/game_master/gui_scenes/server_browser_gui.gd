class_name ServerBrowserGUI
extends GUIScene

@onready var _servers_container: VBoxContainer = $ServersContainer
@onready var _action_panel: VBoxContainer = $ActionPanel
@onready var _selected_server_label: Label = $ActionPanel/SelectedServerLabel
@onready var _play_button: Button = $ActionPanel/PlayButton
@onready var _upload_button: Button = $ActionPanel/UploadNewGameButton
@onready var _status_label: Label = $StatusLabel

const SERVERS: Array = [
	{"name": "Local Server", "ip": "ws://127.0.0.1:55555"},
]

var _selected_server: Dictionary = {}


func _ready() -> void:
	_action_panel.visible = false
	_populate_servers()
	_play_button.pressed.connect(_on_play_pressed)
	_upload_button.pressed.connect(_on_upload_pressed)


func _populate_servers() -> void:
	for server in SERVERS:
		var btn := Button.new()
		btn.text = "%s  |  %s" % [server["name"], server["ip"]]
		btn.custom_minimum_size = Vector2(450, 60)
		btn.pressed.connect(_on_server_selected.bind(server))
		_servers_container.add_child(btn)


func _on_server_selected(server: Dictionary) -> void:
	_selected_server = server
	_selected_server_label.text = server["name"]
	_action_panel.visible = true


func _on_play_pressed() -> void:
	if _selected_server.is_empty():
		return
	set_status("Connecting to %s..." % _selected_server["name"])
	send_gm_signal(ButtonPressedEvent.new(ButtonPressedEvent.ButtonType.PLAY_ON_SERVER, _selected_server["ip"]))


func _on_upload_pressed() -> void:
	if _selected_server.is_empty():
		return
	send_gm_signal(ButtonPressedEvent.new(ButtonPressedEvent.ButtonType.UPLOAD_GAME, _selected_server["ip"]))


func set_status(status_text: String) -> void:
	if _status_label:
		_status_label.text = status_text


func initialize(_args: Variant) -> void:
	pass
