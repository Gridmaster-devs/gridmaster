class_name GameGrid
## Represents the map, which is a grid of grid tiles

## all the tiles on the map
var tiles : Array2D


# TODO: In the future should ask for a map to convert into a game grid
func _init(width : int, height : int):
	tiles = Array2D.new(width, height)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
