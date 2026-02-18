class_name ClickTracker
## Class that handles mouse clicking input
## and emits a signal when a click is detected.

## Emitted when the click tracker detects a click
signal clicked(button : MouseButton)

## Time window for what counts as a a click
## I.e. if the time between pressing the mouse button down
## and raising it is less than this value, it will count as a click
const CLICK_WINDOW = 500

## Stores the time when the specific mouse key was pressed down.
## Used to detect whether the user is clicking or dragging.
var _keypress_times : Dictionary[MouseButton, int]

## Takes in an event and emits clicked if a click is registered
func handle_input(event : InputEvent) -> void:
	# Button was just pressed down
	if event is InputEventMouseButton:
		var button : MouseButton = event.button_index
		var pressed : bool = event.pressed
	
		if pressed:
			_keypress_times.set(button, Time.get_ticks_msec())
		
		# Button was just released
		else:
			var time_diff : int = Time.get_ticks_msec() - _keypress_times.get(button, 0)
			# Time between pressing down and releasing the button is within the specified window
			if time_diff < CLICK_WINDOW:
				clicked.emit(button)
