extends Node
## Object that represents the rule arguments given at game creation

# The fight function must have the signature (unit1, unit2) -> void
# It determines how a fight happens and executes it
# It does not and should not remove units from the map. That is the job
# of the end turn function in the game master

# The damage function must have the signature (unit1, unit2) -> int.
# It determines how much damage is dealt in an attack

# The hit function must have the signature (unit1, unit2) -> bool.
# It determines whether the hit goes through or not

# The unit initiative function must have the signature (unit_array) -> void.
# It takes in an array of units and sorts them according to some criteria

## The types of arguments
enum ArgType {FIGHT_FUNC, DAMAGE_FUNC, HIT_FUNC, UNIT_INITIATIVE_FUNC}


# Percent range is what the accuracy, dodge change, etc. values are defined up to.
#
# Ex. with the value 100, 50 dodge means 50% dodge chance, but
# with the value 1000, 50 dodge chance means 5% dodge chance.

# Combat rounds is how many rounds there are in combat, i.e.
# how many times each unit has a go at taking a shot at the other

## The types of non-function arguments, usually floats, ints, or booleans
enum ArgVarType {PERCENT_RANGE, COMBAT_ROUNDS}

# This is required for some of the functions
# Ex. the fight function might need to know what tile the unit is standing on
var _game_state : GameState

## The dictionary containing the function arguments themselves
var args : Dictionary[ArgType, Callable]

## The dictionary containing the non-function arguments
var arg_vars : Dictionary[ArgVarType, Variant]



# -----
# FLAGS
# -----



# MoveAction flags

## Whether the units should stop their movement after fighting. Default: true.
var stop_after_fighting : bool:
	get: return _stop_after_fighting

var _stop_after_fighting : bool = true
const MA_STOP_AFTER_FIGHTING = 1


## Sets the flags for the move action
func set_move_action_flags(flags : int):
	if (flags & MA_STOP_AFTER_FIGHTING > 0):
		_stop_after_fighting = true
	else:
		_stop_after_fighting = false


# Pathfinding flags

# This is kind of useless right now
## Whether tiles with enemy units are valid targets to move to
var can_move_to_enemy : bool:
	get: return _can_move_to_enemy

var _can_move_to_enemy : bool = true
const PF_CAN_MOVE_TO_ENEMY = 1


# This is kind of useless right now
## Whether a unit can pathfind through friendly units (not end up on top of them, just move through)
var can_move_through_friendly : bool:
	get: return _can_move_through_friendly

var _can_move_through_friendly : bool = true
const PF_CAN_MOVE_THROUGH_FRIENDLY = 2


## Whether friendly units are valid movement targets
var can_target_friendly : bool:
	get: return _can_target_friendly

var _can_target_friendly : bool = true
const PF_CAN_TARGET_FRIENDLY = 4


## Whether you can overlap movement targets of friendly units
var movement_target_overlap_allowed : bool:
	get: return _movement_target_overlap_allowed

var _movement_target_overlap_allowed : bool = true
const PF_MOVEMENT_TARGET_OVERLAP_ALLOWED = 8


## Sets the flags for pathfinding
func set_pathfinding_flags(flags : int):
	if (flags & PF_CAN_MOVE_TO_ENEMY > 0):
		_can_move_to_enemy = true
	else:
		_can_move_to_enemy = false
	
	if (flags & PF_CAN_MOVE_THROUGH_FRIENDLY > 0):
		_can_move_through_friendly = true
	else:
		_can_move_through_friendly = false
	
	if (flags & PF_CAN_TARGET_FRIENDLY > 0):
		_can_target_friendly = true
	else:
		_can_target_friendly = false
	
	if (flags & PF_MOVEMENT_TARGET_OVERLAP_ALLOWED > 0):
		_movement_target_overlap_allowed = true
	else:
		_movement_target_overlap_allowed = false



# -----
# FUNCTION GENERATORS
# -----


## Gives a random number between 0 and PERCENT RANGE (inclusive)
func rand_range_val() -> int:
	return randi_range(0, arg_vars.get(ArgVarType.PERCENT_RANGE))


## Default fight function
##
## There are N combat rounds, and in each round both units try to deal damage to each other
## with the attacking unit going first. If either unit takes lethal damage, combat stops.
## In order to deal damage, a unit's armor piercing must be higher or equal to the other unit's armor.
func _gen_default_fight_func() -> void:
	var fight_func = func(unit1 : Unit, unit2 : Unit):
		if (unit1.is_dead() or unit2.is_dead()): return
		
		var u1_start_hp = unit1.hp
		var u2_start_hp = unit2.hp
		
		var pr = arg_vars.get(ArgVarType.PERCENT_RANGE)
		var hit_func : Callable = args.get(ArgType.HIT_FUNC)
		var damage_func : Callable = args.get(ArgType.DAMAGE_FUNC)
		
		# Whether the units can be damaged by the other
		var tile_protection : int = _game_state.grid.get_tile_vec(unit2.grid_position).protection
		var u2_damageable : bool = unit1.piercing >= unit2.armor
		var u1_damageable : bool = unit2.piercing >= unit1.armor
		
		for cr : int in range(0, arg_vars.get(ArgVarType.COMBAT_ROUNDS)):
			
			# If unit 1 hits unit 2
			if (u2_damageable and hit_func.call(unit1, unit2) == true):
				
				# Unit 2 is defending, so the damage it takes is reduced by the protection
				# of the tile it's standing on
				var dmg_multiplier : float = max(float(pr - tile_protection) / float(pr), 0)
				unit2.take_damage(roundi(damage_func.call(unit1, unit2) * dmg_multiplier))
				
			
			if unit2.is_dead():
				break
			
			# If unit 2 hits unit 1
			if (u1_damageable and hit_func.call(unit2, unit1) == true):
				
				# Unit 1 does not benefit from the terrain bonus because it is attacking
				unit1.take_damage(damage_func.call(unit2, unit1))
			
			if unit1.is_dead():
				break
		
		unit1.set_fought(unit2.unit_id)
		unit2.set_fought(unit1.unit_id)
		
		MessageDispatcher.broadcast_message("[Unit %s : %s] attacked [Unit %s : %s], dealing %s damage and taking %s damage." % [unit1.unit_id, unit1.team_name, unit2.unit_id, unit2.team_name, (u2_start_hp - unit2.hp), (u1_start_hp - unit1.hp)])
		
	
	args.set(ArgType.FIGHT_FUNC, fight_func)


## Default damage function.
## Simply returns the attack of the attacking unit
func _gen_default_damage_func() -> void:
	var damage_func = func(unit1 : Unit, _unit2 : Unit) -> int:
		return unit1.attack

	args.set(ArgType.DAMAGE_FUNC, damage_func)


## Default hit function.
##
## Tests whether the unit hits first and then whether
## the other unit dodges. If the accuracy check goes through and no dodge happens,
## the hit is confirmed
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


## Default initiative function.
##
## Sorts the units by movement speed (higher goes first) and a luck roll
## that ranges from 0 to 1 in order to resolve tiebreakers
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
	


# -----
# INIT AND GODOT PREDEFINED
# -----


# This is necessary because _init() does not work with autoloaded objects
## Initializes the GameArgs object.
func initialize(gs : GameState) -> void:
	_game_state = gs
	
	arg_vars.set(ArgVarType.PERCENT_RANGE, 100)
	
	# TODO: This should be set in the game definition
	arg_vars.set(ArgVarType.COMBAT_ROUNDS, 4)
	
	# This should be replaced with reading arguments from the game definition
	# and then generating the appopriate function
	_gen_default_fight_func()
	_gen_default_initiative_func()
	_gen_default_hit_func()
	_gen_default_damage_func()
