class_name GameArgs
## Class that represents the rule arguments given at game creation

## The types of arguments
enum ArgType {FIGHT_FUNC, DAMAGE_FUNC, HIT_FUNC, UNIT_INITIATIVE_FUNC}

## What the accuracy, dodge change, etc. are defined up to.
##
## Ex. with the value 100, 50 dodge means 50% dodge chance, but
## with the value 1000, 50 dodge chance means 5% dodge chance.
const PERCENT_RANGE : int = 100

# The fight function must have the signature (unit1, unit2) -> void
# It determines how a fight happens and executes it
# It does not and should not remove units from the map. That is the job
# of the end turn function in the game master

# The damage function must have the signature (unit) -> int.
# It determines what damage the unit deals

# The hit function must have the signature (unit1, unit2) -> bool.
# It determines whether the hit goes through or not

# The unit initiative function must have the signature (unit_array) -> void.
# It takes in an array of units and sorts them according to some criteria

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
	

# Gives a random number between 0 and PERCENT RANGE (inclusive)
func rand_range_val() -> int:
	return randi_range(0, PERCENT_RANGE)


# TODO: PUT PROPER FIGHT FUNC HERE
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
	var hit_func = func(unit1 : Unit, unit2 : Unit) -> bool:
		if (rand_range_val() > unit1.accuracy):
			# Unit 1 missed
			return false
		
		if (rand_range_val() <= unit2.dodge):
			# Unit 2 dodged
			return false
		
		# Unit 1 hit the target
		return true

	args.set(ArgType.HIT_FUNC, hit_func)

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
	
