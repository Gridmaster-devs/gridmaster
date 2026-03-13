class_name GridGraphicsViewport
extends SubViewport
## Class that represents the Grid Graphics viewport


## Resizes the viewport to be of the specified size
## Called by the Grid Graphics object at the start
func resize(new_size : Vector2) -> void:
	self.size = new_size


# We're sending the raw input events back to the game master to be handled,
# as it makes sense to handle them there because it's responsible for handling the GUI.

# This is necessary because in Godot, non-gui events propagate from the viewport, so they cannot be
# caught by the gamemaster by itself

# For confused future developers, look up how event propagation works in Godot in the docs
func _unhandled_input(event: InputEvent) -> void:
	get_tree().scene_tree.call_group(GameMaster.GROUP_NAME, GameMaster.RAW_INPUT_FUNC_NAME, event)
