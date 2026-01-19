extends Control

@onready var tile_map = $"../../TileMapLayer"
@onready var sub_viewport = $"../.."
@onready var cam = $"../../Camera2D"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	queue_redraw()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var tile_size = tile_map.tile_set.tile_size 
	var screen_size = Vector2(20000, 20000)
	var n_cols := int(screen_size.x / tile_size.x) + 2
	var n_rows := int(screen_size.y / tile_size.y) + 2
	for y in range(n_rows):
		var cur_y = tile_size.y * y
		draw_line(Vector2(0, cur_y),Vector2(screen_size.x, cur_y), Color.AQUA, 1.0)
	for x in range(n_cols): 
		var cur_x = x * tile_size.x
		draw_line(Vector2(cur_x, 0),Vector2(cur_x, screen_size.y), Color.AQUA, 1.0)
