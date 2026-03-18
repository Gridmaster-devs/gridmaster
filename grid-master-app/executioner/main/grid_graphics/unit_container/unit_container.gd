class_name UnitContainer
extends Sprite2D
## Class that represents a single unit on the battlefield

# object with attributes shared by all units of the same type
var unit: Unit
@onready var unit_id_label : RichTextLabel = $UnitIDLabel

func getUnit() -> Unit: 
	return unit


func getScreenPosition() -> Vector2i:
	return position


# This is required because _init() does not work when instantiating an instance
# of a scene in Godot
## Initalizes the instance of the class
func initialize(internal_unit: Unit, screen_pos: Vector2) -> void:
	unit = internal_unit
	position = screen_pos
	initSprite()


## Initalizes the sprite and the outline shader
func initSprite():
	if unit.type.texture != null: 
		texture = unit.type.texture
	else:
		var img := preload("res://common/media/gridmaster_default_unit.png").get_image()
		var tex := ImageTexture.create_from_image(img)
		tex.set_size_override(Vector2i(GridGraphics.TILE_SIZE, GridGraphics.TILE_SIZE))
		texture = tex
	
	set_instance_shader_parameter("team_color", unit.team.color)
	unit_id_label.text = String.num_int64(unit.unit_id)


func update_screen_position(pos: Vector2i): 
	position = pos
