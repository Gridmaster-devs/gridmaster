@abstract
class_name GameAction
extends RefCounted
## Class that represents an action a player can take

var _game_data_provider: GameDataManager
var player_id : int ## The player attempting to make the action

## Produces a deep copy of the object
@abstract func deep_copy(unit: Unit) -> GameAction
