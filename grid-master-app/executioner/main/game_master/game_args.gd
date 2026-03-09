class_name GameArgs
## Class that represents the rule arguments given at game creation

## The types of arguments
enum ArgType {FIGHT_FUNC, DAMAGE_FUNC, HIT_FUNC, UNIT_INITIATIVE_FUNC}

# The fight function must have the signature of (unit1, unit2) -> void
# It determines how a fight happens
# It does not and should not remove units from the map. That is the job
# of the end turn function in the game master

# Bunch of flags for MoveActions
const FLAG_STOP_AFTER_FIGHTING = 1
static var stop_after_fighting : bool = true


## The dictionary containing the arguments themselves
var args : Dictionary[ArgType, Callable]

#TODO: Properly add all the different functions

static func DEBUG_init() -> GameArgs:
	var game_args : GameArgs = GameArgs.new()
	
	game_args._gen_default_fight_func()
	game_args._gen_default_initiative_func()
	
	return game_args


static func set_move_action_flags(flags : int):
	if (flags & FLAG_STOP_AFTER_FIGHTING > 0):
		stop_after_fighting = true
	else:
		stop_after_fighting = false
	
	

# PUT PROPER FIGHT FUNC HERE
func _gen_default_fight_func() -> void:
	var fight_func = func(unit1 : Unit, unit2 : Unit):
		unit1.take_damage(unit2.get_damage())
		unit2.take_damage(unit1.get_damage())
		
		unit1.set_fought(unit2.unit_id)
		unit2.set_fought(unit1.unit_id)
	
	args.set(ArgType.FIGHT_FUNC, fight_func)

func _gen_default_damage_func() -> void:
	pass

func _gen_default_hit_func() -> void:
	pass


func _gen_default_initiative_func() -> void:
	
	# Dictionary for holding the luck value for each unit
	var luck_dict : Dictionary[Unit, float] = {}
	
	# Creating the function used for sorting the units
	var sort_func = func(unit1 : Unit, unit2 : Unit):
		return unit1.get_move_speed() + luck_dict[unit1] > unit2.get_move_speed() + luck_dict[unit2]
	
	var initiative_func = func(units : Array[Unit]):
		
		# We're rolling a luck value between 0 and 1 to solve tiebreakers
		# of units with the same initiative value
		for unit : Unit in units:
			luck_dict.set(unit, randf())
		
		units.sort_custom(sort_func)
		
	
	args.set(ArgType.UNIT_INITIATIVE_FUNC, initiative_func)



func _init() -> void:
	pass
	
