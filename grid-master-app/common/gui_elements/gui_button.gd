class_name GUIButton
extends Button
## Wrapper for the button class that exists for the purposes
## of input handling

var _click_tracker := ClickTracker.new()

func _clicked(button : MouseButton) -> void:
	if button == MOUSE_BUTTON_LEFT:
		pressed.emit()

# Exists solely to eat user input so it doesn't get passed down to the graphics element
func _gui_input(event: InputEvent) -> void:
	accept_event()
	_click_tracker.handle_input(event)


func _ready() -> void:
	_click_tracker.clicked.connect(_clicked)
