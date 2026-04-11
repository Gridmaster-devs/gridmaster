class_name UnitContainer
extends Sprite2D
## Class that represents a single unit on the battlefield

# WARNING used to have reference to Unit but since UnitContainers are ephemeral
# at the time of writing this was unnecessary. If a reference is needed at some point
# again, use a more sophisticated method according to the normalized data model
#var unit: Unit
@onready var unit_id_label : RichTextLabel = $UnitIDLabel

func getScreenPosition() -> Vector2i:
	return position


# This is required because _init() does not work when instantiating an instance
# of a scene in Godot
## Initalizes the instance of the class
func initialize(unit: Unit, screen_pos: Vector2) -> void:
	position = screen_pos
	initSprite(unit)


## Initalizes the sprite and the outline shader
func initSprite(unit: Unit):
	if unit.type.texture != null: 
		texture = unit.type.texture
		texture.set_size_override(Vector2i(GridGraphics.TILE_SIZE, GridGraphics.TILE_SIZE))
	else:
		var img := preload("res://common/media/gridmaster_default_unit.png").get_image()
		var tex := ImageTexture.create_from_image(img)
		tex.set_size_override(Vector2i(GridGraphics.TILE_SIZE, GridGraphics.TILE_SIZE))
		texture = tex
	
	set_instance_shader_parameter("team_color", unit.team.color)
	if (GameArgs.no_unit_numbers == false):
		unit_id_label.text = String.num_int64(unit.unit_id)


func update_screen_position(pos: Vector2i): 
	position = pos
