extends TileMapLayer


@onready var parent_ref = $"../../../../../.."


func gen_map(): 
	var width = parent_ref.width
	var height = parent_ref.height
	for x in range(width):
		for y in range(height):
			set_cell(Vector2i(x, y), 1, Vector2i(0, 0), 0)


func _ready() -> void:
	gen_map()

func resize(): 
	self.clear()
	gen_map()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
