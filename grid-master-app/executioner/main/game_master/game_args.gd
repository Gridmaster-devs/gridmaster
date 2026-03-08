class_name GameArgs
## Class that represents the rule arguments given at game creation

## The types of arguments
enum ArgType {FIGHT_FUNC, DAMAGE_FUNC, HIT_FUNC, INITIATIVE_FUNC}

## The dictionary containing the arguments themselves
var args : Dictionary[ArgType, Callable]
