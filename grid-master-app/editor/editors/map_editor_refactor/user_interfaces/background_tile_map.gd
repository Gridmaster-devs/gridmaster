class_name BackgroundTileMap
extends TileMapLayer


func gen_map(width: int, height: int): 
	for x in range(width):
		for y in range(height):
			set_cell(Vector2i(x, y), 1, Vector2i(0, 0), 0)

func _ready() -> void:
	pass

func regenerate(width: int, height: int): 
	self.clear()
	gen_map(width, height)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
