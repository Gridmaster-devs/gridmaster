extends TileMapLayer


@export var width = 10
@export var height = 10


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for x in range(-width / 2, width / 2 + 1):
		for y in range(-height / 2, height / 2 + 1):
			set_cell(Vector2i(x, y), 1, Vector2i(0, 0), 0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
