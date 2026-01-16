class_name GameDefinitionResource
extends Resource

@export var game_name : String
@export var units : Array[UnitResourceDict]
@export var map : GameMap

func save_units(unit_array : Array[UnitResourceDict]):
	if (unit_array != null):
		units.clear()
		units = unit_array.duplicate_deep()

func load_units() -> Array[UnitResourceDict]:
	return units.duplicate_deep()
	

func save_name(name_p : String):
	if name_p != null:
		game_name = name_p
		

func load_name() -> String:
	if game_name != null:
		return game_name
	else:
		game_name = ""
		return game_name


func saveMap(map_p : GameMap):
	if (map_p == null): return
	
	map = map_p
	
	
func loadMap() -> GameMap:
	return map
