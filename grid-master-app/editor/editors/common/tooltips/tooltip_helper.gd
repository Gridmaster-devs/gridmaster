@tool
class_name TooltipHelper
extends RefCounted

const WarningIcon = preload("res://editor/editors/common/tooltips/warning_icon.gd")

static func apply(control: Control, context: String, key: String) -> void:
	var description := EditorTooltips.get_tooltip(context, key)
	if description.is_empty():
		return
	control.tooltip_text = description
	if control.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		control.mouse_filter = Control.MOUSE_FILTER_PASS
	if EditorTooltips.has_warning(context, key) and not control.has_meta("unused_warning"):
		control.set_meta("unused_warning", true)
		var warning := Control.new()
		warning.name = "UnusedFeatureWarning"
		warning.set_script(WarningIcon)
		if control is Label:
			control.add_child(warning)
			var width := control.get_theme_font("font").get_string_size(control.text, HORIZONTAL_ALIGNMENT_LEFT, -1, control.get_theme_font_size("font_size")).x
			control.custom_minimum_size.x = maxf(control.custom_minimum_size.x, width + (36 if control.horizontal_alignment != HORIZONTAL_ALIGNMENT_LEFT else 18))
			warning.position = Vector2(width + 4, 0)
			warning.size = Vector2(14, 14)
		elif control is Button:
			for state in ["normal", "hover", "pressed", "disabled"]:
				var style := control.get_theme_stylebox(state).duplicate() as StyleBox
				style.content_margin_right = style.get_content_margin(SIDE_RIGHT) + 18
				control.add_theme_stylebox_override(state, style)
			control.add_child(warning)
			var text_width := control.get_theme_font("font").get_string_size(control.text, HORIZONTAL_ALIGNMENT_LEFT, -1, control.get_theme_font_size("font_size")).x
			warning.set_anchors_preset(Control.PRESET_CENTER)
			warning.offset_left = text_width / 2 - 5
			warning.offset_top = -7
			warning.offset_right = text_width / 2 + 9
			warning.offset_bottom = 7
		else:
			control.get_parent().add_child(warning)
			control.get_parent().move_child(warning, control.get_index() + 1)

static func add_label_before(input: Control, text: String, context: String, key: String) -> Label:
	var label := Label.new()
	label.text = text
	input.get_parent().add_child(label)
	input.get_parent().move_child(label, input.get_index())
	apply(label, context, key)
	return label
