@abstract
class_name GameAction
extends RefCounted
## Class that represents an action a player can take

var player_id : int ## The player attempting to make the action

@abstract func execute(game_state : GameState)
