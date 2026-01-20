class_name StrategicTileInformation
extends Resource 

@export var source: int
@export var name: String
@export var protection: int
@export var movement: int
@export var hiding: int
@export var texture: Texture2D

func _init(s := -1, n := "", p := 0, m := 0, h := 0, t := Texture2D.new()):
	source = s
	name = n
	protection = p
	movement = m
	hiding = h
	texture = t
	
