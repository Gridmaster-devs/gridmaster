class_name GameState
## Class that represents everything that makes up the current state of the game, ex. the units, the map, etc


var grid : GameGrid ## Grid that represents the map
var units : Array[Unit] = [] ## All the units in the game, NOTE: also stored in each map tile
var players : Array[Player] = [] ## All the players in the game
var teams : Array[Team] = [] ## All the teams in the game
var unit_types : Array[UnitType] ## All the types of units in the game


## tracks the id to be given to the next unit that spawns
## increments by one each time
var unit_id_count : int = 0

var turn_number : int = 0 ## What turn it is
var game_name : String

## The actions the player plans to do
var tentative_actions : Array[GameAction] = []

## The actions the player locked in by pressing "end turn"
var action_queue : Array[GameAction] = []


# These functions exist so that the graphics element can request the
# map and units so it can draw them
## Returns the game grid
func getGameGrid() -> GameGrid:
	return grid


# These functions exist so that the graphics element can request the
# map and units so it can draw them
## Returns the unit array
func getUnits() -> Array[Unit]:
	return units
	

## Gets a unit id for a new unit
func getNewUnitId() -> int:
	unit_id_count += 1
	return unit_id_count


## Creates a unit for testing
func createDebugUnit(position : Position2DInt) -> void:
	var unit = Unit.new(UnitType.debugType(), getNewUnitId(), -1, position)
	addUnit(unit)
	

## Adds a unit to the game
func addUnit(unit : Unit):
	grid.addUnit(unit)
	units.append(unit)


# TODO: This should take a map resource and turn it into the grid instead of asking for
# map width and height
func _init(map_width : int, map_height : int, players_p : Array[Player], teams_p : Array[Team], game_name_p : String):
	grid = GameGrid.new(map_width, map_height)
	players = players_p
	teams = teams_p
	game_name = game_name_p
