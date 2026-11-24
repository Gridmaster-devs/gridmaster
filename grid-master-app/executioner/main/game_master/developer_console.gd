class_name DeveloperConsole
extends CanvasLayer
## Modal developer command input and scrollable transcript.

signal opened

const COMMANDS: Dictionary[String, String] = {
	"help": "List commands and syntax.",
	'spawn "Unit Type" X Y': "Spawn a unit at zero-based coordinates.",
	"state": "Show the current game state.",
	"units": "List units on the board.",
	"types": "List registered unit types.",
	"perf": "Show FPS and the last turn processing time.",
}

var _mode: String = ""
var _previous_focus: Control
var _session_id: int = 0

@onready var _game_master: GameMaster = get_parent()
@onready var _transcript: RichTextLabel = %Transcript
@onready var _command_line: LineEdit = %CommandLine


func _ready() -> void:
	_command_line.text_submitted.connect(_on_text_submitted)


func _input(event: InputEvent) -> void:
	if _mode.is_empty():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F2 or (visible and event.keycode == KEY_ESCAPE):
			get_viewport().set_input_as_handled()
			if visible:
				_close()
			else:
				_open()
			return
	if visible and (event is InputEventJoypadButton or event is InputEventJoypadMotion \
			or event.is_action("ui_focus_next") or event.is_action("ui_focus_prev")):
		get_viewport().set_input_as_handled()


func _unhandled_input(_event: InputEvent) -> void:
	if visible:
		get_viewport().set_input_as_handled()


## An empty mode closes and clears the console when leaving a game.
func set_session(mode: String) -> void:
	if not OS.is_debug_build():
		return
	_mode = mode
	if _mode.is_empty():
		_session_id += 1
		_close()
		_transcript.clear()
		_command_line.clear()


func is_multiplayer_session() -> bool:
	return _mode == "multiplayer"


func _open() -> void:
	_previous_focus = get_viewport().gui_get_focus_owner()
	show()
	_command_line.grab_focus()
	opened.emit()


func _close() -> void:
	hide()
	if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
		_previous_focus.grab_focus()
	_previous_focus = null


func _on_text_submitted(line: String) -> void:
	var session_id: int = _session_id
	_command_line.clear()
	_transcript.add_text("> %s\n" % line)
	var result: Dictionary = await DEBUG_execute(line)
	if session_id == _session_id:
		_transcript.add_text("%s\n" % result["message"])


func _spawn(args: Array[String]) -> Dictionary:
	var coordinates: Array[int] = []
	for value: String in args.slice(2):
		if not value.is_valid_int():
			return DeveloperCommands.result("invalid_coordinates", "Coordinates must be integers.")
		var digits: String = value.lstrip("+-").lstrip("0")
		if digits.length() > 10:
			return DeveloperCommands.result("out_of_bounds", "The requested tile is outside the map.")
		var coordinate: int = digits.to_int()
		coordinates.append(-coordinate if value.begins_with("-") else coordinate)
	if is_multiplayer_session():
		return await Networking.developer_console_rpc.spawn(args[1], coordinates[0], coordinates[1])
	return _game_master.spawn_local_unit(args[1], coordinates[0], coordinates[1])


func _state(manager: GameDataManager) -> Dictionary:
	var data: Dictionary = {
		"game_name": manager.get_game_name(),
		"mode": _mode,
		"turn_number": manager.get_turn_number(),
		"width": manager.get_grid().width,
		"height": manager.get_grid().height,
		"active_player_id": manager.get_client_player_id(),
		"unit_count": manager.get_units().size(),
		"game_over": _game_master.is_game_over(),
	}
	var message: String = "%s (%s)\nCompleted turns: %d | Map: %d x %d\nPlayer: %d | Units: %d | Game over: %s" % [
		data.game_name, data.mode, data.turn_number, data.width, data.height,
		data.active_player_id, data.unit_count, str(data.game_over),
	]
	return DeveloperCommands.result("ok", message, data)


func _units(manager: GameDataManager) -> Dictionary:
	var units: Array[Dictionary] = []
	var lines: PackedStringArray = []
	for unit: Unit in manager.get_units().values():
		var row: Dictionary = {
			"id": unit.getId(),
			"type": unit.type.unit_name,
			"player_id": unit.get_player_id(),
			"x": unit.grid_position.x,
			"y": unit.grid_position.y,
			"hp": unit.hp,
		}
		units.append(row)
		lines.append("#%d %s | Player %d | (%d, %d) | %d HP" % [
			row.id, row.type, row.player_id, row.x, row.y, row.hp,
		])
	var message: String = "No units on the board." if lines.is_empty() else "\n".join(lines)
	return DeveloperCommands.result("ok", message, {"units": units})


func _types(manager: GameDataManager) -> Dictionary:
	var types: Array[String] = []
	for unit_type: UnitType in manager.get_game_defintion().unit_types.values():
		if not types.has(unit_type.unit_name):
			types.append(unit_type.unit_name)
	types.sort()
	var message: String = "No registered unit types." if types.is_empty() else "\n".join(types)
	return DeveloperCommands.result("ok", message, {"types": types})


func _perf() -> Dictionary:
	var fps: Variant = null if DisplayServer.get_name() == "headless" else Engine.get_frames_per_second()
	var turn_ms: Variant = _game_master.turn_processing_ms
	var fps_text: String = "N/A" if fps == null else "%.1f" % fps
	var turn_text: String = "N/A" if turn_ms == null else "%.3f ms" % turn_ms
	return DeveloperCommands.result("ok", "FPS: %s | Turn processing: %s" % [fps_text, turn_text], {
		"fps": fps, "turn_processing_ms": turn_ms,
	})


## Tokenizes whitespace-delimited words and double-quoted arguments.
func _tokenize(line: String, args: Array[String]) -> bool:
	var index: int = 0
	while index < line.length():
		if line[index] in " \t\r\n":
			index += 1
			continue
		if line[index] == '"':
			index += 1
			var token: String = ""
			while index < line.length() and line[index] != '"':
				if (line[index] == "\\" and index + 1 < line.length()
						and line[index + 1] in ['"', "\\"]):
					index += 1
				token += line[index]
				index += 1
			if index == line.length() or (index + 1 < line.length() and line[index + 1] not in " \t\r\n"):
				return false
			args.append(token)
			index += 1
		else:
			var start: int = index
			while index < line.length() and line[index] not in " \t\r\n":
				if line[index] == '"':
					return false
				index += 1
			args.append(line.substr(start, index - start))
	return true


## TESTING Runs the same command as the overlay and awaits an authoritative spawn reply.
func DEBUG_execute(line: String) -> Dictionary:
	var manager: GameDataManager = _game_master.data_manager
	if _mode.is_empty() or manager == null:
		return DeveloperCommands.result("unavailable", "The developer console is unavailable in this session.")
	var args: Array[String] = []
	if not _tokenize(line, args):
		return DeveloperCommands.result("invalid_syntax", "Double quotes must enclose a whole argument.")
	if args.is_empty():
		return DeveloperCommands.result("empty_command", "Enter a command. See help.")
	if args[0] == "spawn":
		if args.size() != 4:
			return DeveloperCommands.result("invalid_arguments", 'Usage: spawn "Unit Type" X Y')
		return await _spawn(args)
	if args.size() != 1:
		return DeveloperCommands.result("invalid_arguments", "%s takes no arguments. See help." % args[0])
	match args[0]:
		"help":
			var syntax: Dictionary = {}
			var lines: PackedStringArray = []
			for usage: String in COMMANDS:
				syntax[usage.get_slice(" ", 0)] = usage
				lines.append("%s  %s" % [usage, COMMANDS[usage]])
			return DeveloperCommands.result("ok", "\n".join(lines), {"commands": syntax})
		"state":
			return _state(manager)
		"units":
			return _units(manager)
		"types":
			return _types(manager)
		"perf":
			return _perf()
		_:
			return DeveloperCommands.result("unknown_command", 'Unknown command "%s". See help.' % args[0])
