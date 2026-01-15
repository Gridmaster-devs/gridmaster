class_name Position2DInt
## This class exists because Godot doesn't natively support
## 2D vectors with ints. No, seriously.

var x : int
var y : int

func _init(x_p, y_p) -> void:
	x = x_p
	y = y_p
