extends Node2D
class_name UnitContainer
## Class that represents a single unit on the battlefield

# object with attributes shared by all units of the same type
var unit: Unit
var sprite: Sprite2D


func getUnit() -> Unit: 
	return unit

func getScreenPosition() -> Vector2i:
	return position


func _init(internal_unit: Unit, screen_pos: Vector2i) -> void:
	unit = internal_unit
	position = screen_pos
	initSprite()

func initSprite():
	sprite = Sprite2D.new()
	add_child(sprite)
	if unit.type.texture != null: 
		sprite.texture = unit.type.texture
	else:
		var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 0, 0, 1))  # solid red
		var tex := ImageTexture.create_from_image(img)
		sprite.texture = tex


func update_screen_position(pos: Vector2i): 
	position = pos
