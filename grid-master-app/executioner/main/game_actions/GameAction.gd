@abstract
class_name GameAction
extends RefCounted
## Class that represents an action a player can take

var _game_state : GameState ## A reference to the game state for the actions to use
var player_id : int ## The player attempting to make the action
