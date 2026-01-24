extends TileMapLayer

@onready var parent_ref = $"../../../.."

func gen_map(): 
	var width = 100
	var height = 100
	for x in range(width):
		for y in range(height):
			set_cell(Vector2i(x, y), 1, Vector2i(0, 0), 0)


func _ready() -> void:
	gen_map()

func regenerate(): 
	self.clear()
	gen_map()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
