extends Camera2D

var dragging := false
var last_mouse_pos := Vector2.ZERO

@export var zoom_speed = 0.1
@export var min_zoom = 0.4
@export var max_zoom = 2.0

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE :
			if event.pressed:
				dragging = true
				last_mouse_pos = event.position
			else:
				dragging = false
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var old_zoom = self.zoom 
			var new_zoom = self.zoom 
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				new_zoom += Vector2(zoom_speed, zoom_speed)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				new_zoom -= Vector2(zoom_speed, zoom_speed)
			new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
			new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
			var mouse_world := get_global_mouse_position()
			position += (mouse_world - position) * (1 - old_zoom.x / new_zoom.x)
			zoom = new_zoom
		
	if dragging and event is InputEventMouseMotion:
		var delta = event.position - last_mouse_pos
		position -= delta/zoom.x
		last_mouse_pos = event.position
