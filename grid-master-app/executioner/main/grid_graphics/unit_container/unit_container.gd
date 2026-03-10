class_name UnitContainer
extends Sprite2D
## Class that represents a single unit on the battlefield

# object with attributes shared by all units of the same type
var unit: Unit

func getUnit() -> Unit: 
	return unit

func getScreenPosition() -> Vector2i:
	return position


func _init(internal_unit: Unit, screen_pos: Vector2) -> void:
	unit = internal_unit
	position = screen_pos
	initSprite()

func initSprite():
	if unit.type.texture != null: 
		texture = unit.type.texture
	else:
		var img := preload("res://common/media/gridmaster_default_unit.png").get_image()
		var tex := ImageTexture.create_from_image(img)
		tex.set_size_override(Vector2i(GridGraphics.TILE_SIZE, GridGraphics.TILE_SIZE))
		texture = tex

func update_screen_position(pos: Vector2i): 
	position = pos
