class_name EditorMain
extends Node

@onready var unit_editor : UnitEditor = $"TabContainer/Unit editor"
@onready var game_editor : GameEditor = $"TabContainer/Game Editor"
@onready var map_editor : Node = $"TabContainer/Map editor" # TODO: FIX THIS WHEN MAP EDITOR IS ADDED

func get_units() -> Array[UnitResourceDict]:
	return unit_editor.get_units()
	
func set_units(units_p : Array[UnitResourceDict]):
	unit_editor.set_units(units_p)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	unit_editor.link_editor_main(self)
	game_editor.link_editor_main(self)
	# TODO: ADD MAP EDITOR LINK

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
