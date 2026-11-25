extends GutTest

const GameArgsScript = preload("res://executioner/global/game_args.gd")


func test_hit_probability_boundaries() -> void:
	var rules := GameArgsScript.new()
	rules.arg_vars[rules.ArgVarType.PERCENT_RANGE] = 100
	rules._gen_default_hit_func()
	var hit: Callable = rules.args[rules.ArgType.HIT_FUNC]
	var attacker_type: UnitType = UnitType.debugType()
	var defender_type: UnitType = UnitType.debugType()
	var player: Player = Player.DEBUG_new_player()
	var attacker := Unit.new(attacker_type, 1, player, Vector2i.ZERO)
	var defender := Unit.new(defender_type, 2, player, Vector2i.ZERO)

	for accuracy in [0.0, 100.0]:
		for evasion in [0.0, 100.0]:
			attacker_type.attributes[UnitType.UNIT_ATTRIBUTE_TYPE.ACCURACY] = accuracy
			defender_type.attributes[UnitType.UNIT_ATTRIBUTE_TYPE.DODGE] = evasion
			for i in 1000:
				assert_eq(hit.call(attacker, defender), accuracy == 100.0 and evasion == 0.0)
	rules.free()


func test_decimal_accuracy_and_evasion_affect_hit_roll() -> void:
	var rules := GameArgsScript.new()
	rules.arg_vars[rules.ArgVarType.PERCENT_RANGE] = 100
	rules._gen_default_hit_func()
	var hit: Callable = rules.args[rules.ArgType.HIT_FUNC]
	var attacker_type: UnitType = UnitType.debugType()
	var defender_type: UnitType = UnitType.debugType()
	var player: Player = Player.DEBUG_new_player()
	var attacker := Unit.new(attacker_type, 1, player, Vector2i.ZERO)
	var defender := Unit.new(defender_type, 2, player, Vector2i.ZERO)

	# Find a reproducible roll between 75 and 75.3, where truncation changes the result.
	var roll_seed: int = -1
	for candidate in 10000:
		seed(candidate)
		var roll: float = randf() * 100.0
		if roll >= 75.0 and roll < 75.3:
			roll_seed = candidate
			break
	assert_ne(roll_seed, -1, "A suitable deterministic roll should be found")
	if roll_seed != -1:
		attacker_type.attributes[UnitType.UNIT_ATTRIBUTE_TYPE.ACCURACY] = 75.3
		defender_type.attributes[UnitType.UNIT_ATTRIBUTE_TYPE.DODGE] = 0.0
		seed(roll_seed)
		assert_true(hit.call(attacker, defender), "Decimal accuracy should hit")
		attacker_type.attributes[UnitType.UNIT_ATTRIBUTE_TYPE.ACCURACY] = 100.0
		defender_type.attributes[UnitType.UNIT_ATTRIBUTE_TYPE.DODGE] = 75.3
		seed(roll_seed)
		assert_false(hit.call(attacker, defender), "Decimal evasion should dodge")
	rules.free()
