class_name GridGraphicsViewport
extends SubViewport
## Class that represents the Grid Graphics viewport

var scene_tree : SceneTree


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	scene_tree = get_tree()


## Resizes the viewport to be of the specified size
## Called by the Grid Graphics object at the start
func resize(new_size : Vector2) -> void:
	self.size = new_size


# TODO: I don't think this needs to be called every frame.
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# self.size = Vector2i(control_ref.size)
	pass


# We're sending the events back to the grid graphics to be handled.
# This is necessary because the events propagate from the viewport
func _unhandled_input(event: InputEvent) -> void:
	scene_tree.call_group(GridGraphics.GROUP_NAME, GridGraphics.EVENT_INPUT_FUNC_NAME, event)
