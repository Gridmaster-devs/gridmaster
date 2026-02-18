class_name GUIButton
extends Button
## Wrapper for the button class that exists for the purposes
## of input handling


# Exists solely to eat user input so it doesn't get passed down to the graphics element
func _gui_input(_event: InputEvent) -> void:
	accept_event()
