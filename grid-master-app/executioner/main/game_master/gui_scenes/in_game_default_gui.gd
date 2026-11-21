class_name InGameDefaultGUI
extends GUIScene

const RESOURCE_ENTRY_SCENE : PackedScene = preload("res://executioner/main/game_master/gui_scenes/gui_elements/resource_bar/resource_entry.tscn")

@onready var _game_name_label : Label = $TopBar/BarContent/GameNameLabel
@onready var _resources_container : HBoxContainer = $TopBar/BarContent/ResourcesContainer
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

## Shows the amount of each global resource the player has in the top bar, with the
## resource's icon and name. Hidden if the game has no resources.
func set_resources(resources : Dictionary[String, int], icons : Dictionary[String, Texture2D]) -> void:
	for entry in _resources_container.get_children():
		_resources_container.remove_child(entry)
		entry.queue_free()
	for resource_name in resources.keys():
		var entry : ResourceEntry = RESOURCE_ENTRY_SCENE.instantiate()
		entry.init_params(resource_name, resources[resource_name], icons.get(resource_name, null))
		_resources_container.add_child(entry)
	_resources_container.visible = not resources.is_empty()

# Normal _init() does not work when you are instantiating
# a scene from a file
func initialize(game_name : Variant) -> void:
	_game_name_label.text = game_name as String
