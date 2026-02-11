class_name MoveAction
extends UnitAction
## An action that represents a unit moving from place A to place B

# Currently only the first and last tile of the path matter,
# but this could change in the future if we implement, for example,
# land mines.
## Path of nodes the unit is set to travel.
## The first item is always the starting position of the unit,
## and the last item is always the final position of the unit.
var path : Array[Vector2i]


func execute(game_state : GameState):
	game_state.move_unit(unit_id, path.back())
