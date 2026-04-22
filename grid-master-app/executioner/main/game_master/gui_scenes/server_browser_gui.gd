class_name ServerBrowserGUI
extends GUIScene

@onready var _servers_container: VBoxContainer = $ServersContainer
@onready var _action_panel: VBoxContainer = $ActionPanel
@onready var _selected_server_label: Label = $ActionPanel/SelectedServerLabel
@onready var _play_button: Button = $ActionPanel/PlayButton
@onready var _upload_button: Button = $ActionPanel/UploadNewGameButton
@onready var _status_label: Label = $StatusLabel
@onready var _back_button: Button = $BackButton

const SERVERS: Array = [
	{"ip": "wss://gridmaster-server.calmmeadow-c81c2c38.northeurope.azurecontainerapps.io"},
	{"ip": "ws://127.0.0.1:443"},
]

var _selected_server: Dictionary = {}
var _selected_server_name: String = ""
var _status_indicators: Array = []
var _server_buttons: Array = []


func _ready() -> void:
	_action_panel.visible = false
	_populate_servers()
	_play_button.pressed.connect(_on_play_pressed)
	_upload_button.pressed.connect(_on_upload_pressed)
	_back_button.pressed.connect(_on_back_pressed)
	_ping_all_servers()


func _populate_servers() -> void:
	for i in range(SERVERS.size()):
		var server: Dictionary = SERVERS[i]
		var server_name: String = server.get("name", "Server %d" % (i + 1))

		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(450, 60)

		var indicator := ColorRect.new()
		indicator.custom_minimum_size = Vector2(12, 12)
		indicator.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		indicator.color = Color(0.5, 0.5, 0.5)
		_status_indicators.append(indicator)
		row.add_child(indicator)

		var btn := Button.new()
		btn.text = "%s | ..." % server_name
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_server_selected.bind(server, server_name))
		_server_buttons.append(btn)
		row.add_child(btn)

		_servers_container.add_child(row)


func _ping_all_servers() -> void:
	for i in range(SERVERS.size()):
		_ping_server(i)


func _ping_server(index: int) -> void:
	var server: Dictionary = SERVERS[index]
	var server_name: String = server.get("name", "Server %d" % (index + 1))
	var game_name: String = await Networking.query_server_info(server["ip"])
	if game_name.is_empty():
		_status_indicators[index].color = Color.RED
		_server_buttons[index].text = "%s | Offline" % server_name
	else:
		_status_indicators[index].color = Color.GREEN
		_server_buttons[index].text = "%s | %s" % [server_name, game_name]


func _on_server_selected(server: Dictionary, server_name: String) -> void:
	_selected_server = server
	_selected_server_name = server_name
	_selected_server_label.text = server_name
	_action_panel.visible = true


func _on_play_pressed() -> void:
	if _selected_server.is_empty():
		return
	set_status("Connecting to %s..." % _selected_server_name)
	send_gm_signal(ButtonPressedEvent.new(ButtonPressedEvent.ButtonType.PLAY_ON_SERVER, _selected_server["ip"]))


func _on_upload_pressed() -> void:
	if _selected_server.is_empty():
		return
	send_gm_signal(ButtonPressedEvent.new(ButtonPressedEvent.ButtonType.UPLOAD_GAME, _selected_server["ip"]))


func _on_back_pressed() -> void:
	send_gm_signal(ButtonPressedEvent.new(ButtonPressedEvent.ButtonType.BACK))


func set_status(status_text: String) -> void:
	if _status_label:
		_status_label.text = status_text


func refresh_servers() -> void:
	_ping_all_servers()


func initialize(_args: Variant) -> void:
	pass
