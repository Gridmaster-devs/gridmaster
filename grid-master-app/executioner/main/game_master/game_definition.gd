class_name GameDefinition
extends RefCounted

var game_name : String:
	get:
		return game_name
	set(new_name):
		game_name = new_name
		
var unit_types : Dictionary[int, UnitType] = {} ## All the types of units in the game

var pathfinder : DijkstraPathfinder ## Dijkstra pathfinder for unit pathing

## Initializes the unit types from a game definition
func initUnitTypesFromResource(game_definition : GameDefinitionResource, 
								unit_name_type_dict: Dictionary[String, int]) -> void:
	var gd_units : Array[UnitResource] = game_definition.load_units()
	var type_count : int = 0
	for unit in gd_units:
		var cur_unit_type = UnitType.initFromUnitResource(unit, type_count)
		unit_types.set(type_count, cur_unit_type)
		unit_name_type_dict[ cur_unit_type.unit_name] = type_count
		type_count += 1
		

# INFO DEBUG methods
 
## Prints the unit types into a logfile
func printUnitTypes(to_log : bool):
	for type in unit_types.values():
		if (to_log == true):
			GML.log(type._to_string())
		else:
			print(type._to_string())
