class_name EditorMain
extends Node

@onready var unit_editor : UnitEditor = $"TabContainer/Unit editor"
@onready var game_editor : GameEditor = $"TabContainer/Game Editor"
@onready var map_editor : Node = $"TabContainer/Map editor/MapEditor"


# gets the units from the unit editor
# TODO: get a unit pack when those are implemented
func get_units() -> Array[UnitResource]:
	return unit_editor.get_units()


# tells the unit editor to replace the units with the ones from the array
# TODO: Use a unit pack when those are implemented
func set_units(units_p : Array[UnitResource]):
	unit_editor.set_units(units_p)


func getMap() -> GameMap:
	return map_editor.saveMapToResource()


func setMap(map_p : GameMap):
	map_editor.load_from_data(map_p)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	unit_editor.link_editor_main(self)
	game_editor.link_editor_main(self)
	# TODO: ADD MAP EDITOR LINK
