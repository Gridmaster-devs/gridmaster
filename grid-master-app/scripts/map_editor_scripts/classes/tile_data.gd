class_name TileInformation


var source: int
var name: String
var protection: int
var movement: int
var hiding: float
var texture: Texture2D

func _init(s := -1, n := "", p := 0, m := 0, h := 0, t := Texture2D.new()):
	source = s
	name = n
	protection = p
	movement = m
	hiding = h
	texture = t
	
