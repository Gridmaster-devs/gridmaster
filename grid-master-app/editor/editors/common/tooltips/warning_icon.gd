@tool
extends Control

func _ready() -> void:
	custom_minimum_size = Vector2(14, 14)
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = EditorTooltips.WARNING_TEXT
	theme_changed.connect(_update_appearance)
	if get_parent() is Label:
		get_parent().resized.connect(_update_appearance)
	_update_appearance()

func _draw() -> void:
	var color := get_theme_color("font_color", "Label")
	var points := PackedVector2Array([Vector2(7, 1), Vector2(13, 12), Vector2(1, 12), Vector2(7, 1)])
	draw_polyline(points, color, 1.1, true)
	draw_line(Vector2(7, 4), Vector2(7, 8), color, 1.2, true)
	draw_circle(Vector2(7, 10), 0.8, color)

func _update_appearance() -> void:
	var label := get_parent() as Label
	if label:
		var width := label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
		var style := label.get_theme_stylebox("normal")
		var left := style.get_content_margin(SIDE_LEFT)
		var available_width := label.size.x - left - style.get_content_margin(SIDE_RIGHT)
		var start := left
		if label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER:
			start += maxf(0.0, (available_width - width) / 2)
		elif label.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT:
			start += maxf(0.0, available_width - width)
		position = Vector2(start + width + 4, maxf(0.0, (label.size.y - 14) / 2))
	queue_redraw()
