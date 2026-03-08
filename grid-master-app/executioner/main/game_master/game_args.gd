class_name GameArgs
## Class that represents the rule arguments given at game creation

## The types of arguments
enum ArgType {FIGHT_FUNC, DAMAGE_FUNC, HIT_FUNC, UNIT_INITIATIVE_FUNC}

## The dictionary containing the arguments themselves
var args : Dictionary[ArgType, Callable]

#TODO: Properly add all the different functions

static func DEBUG_init() -> GameArgs:
	var game_args : GameArgs = GameArgs.new()
	
	game_args._gen_default_fight_func()
	
	return game_args
	
func _gen_default_fight_func() -> void:
	var fight_func = func(unit1 : Unit, unit2 : Unit):
		unit1.hp -= unit2.get_damage()
		unit2.hp -= unit1.get_damage()
		
		unit1.set_fought(unit2.unit_id)
		unit2.set_fought(unit1.unit_id)
	
	args.set(ArgType.FIGHT_FUNC, fight_func)

func _gen_default_damage_func() -> void:
	pass

func _gen_default_hit_func() -> void:
	pass



func _init() -> void:
	pass
	
