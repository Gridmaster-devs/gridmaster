class_name GameDefinitionResource
extends Resource

@export var game_name : String
@export var units : Array[UnitResourceDict]
# TODO: MAP DATA GOES HERE

func save_units(unit_array : Array[UnitResourceDict]):
	if (unit_array != null):
		units.clear()
		for unit in unit_array:
			units.append(unit)

func load_units() -> Array[UnitResourceDict]:
	var return_array : Array[UnitResourceDict] = []
	for unit in units:
		return_array.append(unit)
	return return_array
	

func save_name(name_p : String):
	if name_p != null:
		game_name = name_p
		

func load_name() -> String:
	if game_name != null:
		return game_name
	else:
		game_name = ""
		return game_name
	
# TODO: add map functions here

#func _init(name_p : String, units_p : Array[UnitResourceDict]):
	#if (name_p != null and units_p != null):
		#game_name = name_p
		#save_units(units_p)
	
