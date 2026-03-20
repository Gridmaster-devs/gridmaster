class_name GameDefinitionResource
extends Resource

@export var game_name : String
@export var units : Array[UnitResource]
@export var map : MapResource
@export var unit_layer: Array2D
@export var team_uis: Array[TeamUiRes]

func save_units(unit_array : Array[UnitResource]):
	if (unit_array != null):
		units.clear()
		units = unit_array.duplicate_deep()

func load_units() -> Array[UnitResource]:
	return units.duplicate_deep()

func load_unit_layer() -> Array2D:
	return unit_layer.duplicate(true)

func save_unit_layer(ulayer: Array2D) -> void: 
	unit_layer = ulayer

func save_team_uis(uis: Array[TeamUiRes]) -> void:
	team_uis = uis

func load_team_uis() -> Array[TeamUiRes]: 
	return team_uis.duplicate(true)

func save_name(name_p : String):
	if name_p != null:
		game_name = name_p
		

func load_name() -> String:
	if game_name != null:
		return game_name
	else:
		game_name = ""
		return game_name


func saveMap(map_p : MapResource):
	if (map_p == null): return
	
	map = map_p




func loadMap() -> MapResource:
	return map
