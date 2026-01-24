extends TileMapLayer

@onready var parent_ref = $"../../../.."

var width: int
var height: int 

func gen_map(): 
	for x in range(width):
		for y in range(height):
			set_cell(Vector2i(x, y), 1, Vector2i(0, 0), 0)


func _ready() -> void:
	pass

func resize(w: int, h: int):
	width = w
	height = h
	regenerate()

func regenerate(): 
	self.clear()
	gen_map()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
