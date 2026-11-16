class_name InGameDefaultGUI
extends GUIScene

@onready var _game_name_label : Label = $GameNameLabel
@onready var _resources_label : Label = $ResourcesLabel
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

func set_eliminated() -> void:
	_end_turn_button.text = "Eliminated"
	_end_turn_button.disabled = true

func set_game_over() -> void:
	_end_turn_button.text = "Game Over"
	_end_turn_button.disabled = true

## Shows the amount of each global resource the player has. Hidden if the game has no resources.
func set_resources(resources : Dictionary[String, int]) -> void:
	var parts : Array[String] = []
	for resource_name in resources.keys():
		parts.append("%s: %d" % [resource_name, resources[resource_name]])
	_resources_label.text = "   ".join(parts)
	_resources_label.visible = not parts.is_empty()

# Normal _init() does not work when you are instantiating
# a scene from a file
func initialize(game_name : Variant) -> void:
	_game_name_label.text = game_name as String
