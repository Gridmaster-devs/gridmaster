@tool
class_name TooltipHelper
extends RefCounted

const WarningIcon = preload("res://editor/editors/common/tooltips/warning_icon.gd")
const WARNING_BUTTON_STATES := ["normal", "hover", "pressed", "disabled", "hover_pressed"]

static func apply(control: Control, context: String, key: String, show_warning_icon: bool = true) -> void:
	var description := EditorTooltips.get_tooltip(context, key)
	if description.is_empty():
		return
	if not show_warning_icon and EditorTooltips.has_warning(context, key):
		description += "\n" + EditorTooltips.WARNING_TEXT
	control.tooltip_text = description
	if control.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		control.mouse_filter = Control.MOUSE_FILTER_PASS
	if show_warning_icon and EditorTooltips.has_warning(context, key) and not control.has_meta("unused_warning"):
		control.set_meta("unused_warning", true)
		var warning := Control.new()
		warning.name = "UnusedFeatureWarning"
		warning.set_script(WarningIcon)
		if control is Label:
			control.add_child(warning)
			var width := control.get_theme_font("font").get_string_size(control.text, HORIZONTAL_ALIGNMENT_LEFT, -1, control.get_theme_font_size("font_size")).x
			var style := control.get_theme_stylebox("normal")
			var margins := style.get_content_margin(SIDE_LEFT) + style.get_content_margin(SIDE_RIGHT)
			control.custom_minimum_size.x = maxf(control.custom_minimum_size.x, width + margins + (36 if control.horizontal_alignment != HORIZONTAL_ALIGNMENT_LEFT else 18))
			warning.size = Vector2(14, 14)
		elif control is Button:
			var button_ref: WeakRef = weakref(control)
			control.theme_changed.connect(_queue_warning_button_styles.bind(button_ref))
			_refresh_warning_button_styles(button_ref)
			control.add_child(warning)
			var text_width := control.get_theme_font("font").get_string_size(control.text, HORIZONTAL_ALIGNMENT_LEFT, -1, control.get_theme_font_size("font_size")).x
			warning.set_anchors_preset(Control.PRESET_CENTER)
			warning.offset_left = text_width / 2 - 5
			warning.offset_top = -7
			warning.offset_right = text_width / 2 + 9
			warning.offset_bottom = 7


static func _queue_warning_button_styles(button_ref: WeakRef) -> void:
	var button := button_ref.get_ref() as Button
	if button == null or button.has_meta("unused_warning_refresh_pending"):
		return
	# Coalesce notifications and wait for EditorThemes.apply() to finish merging.
	button.set_meta("unused_warning_refresh_pending", true)
	_refresh_warning_button_styles.call_deferred(button_ref)


static func _refresh_warning_button_styles(button_ref: WeakRef) -> void:
	var button := button_ref.get_ref() as Button
	if button == null:
		return
	# Override edits emit theme_changed themselves; ignore only our own edits.
	var on_theme_changed := _queue_warning_button_styles.bind(button_ref)
	button.theme_changed.disconnect(on_theme_changed)
	for state in WARNING_BUTTON_STATES:
		button.remove_theme_stylebox_override(state)
	for state in WARNING_BUTTON_STATES:
		# Control's lookup preserves the active theme and its type variation.
		var style := button.get_theme_stylebox(state).duplicate() as StyleBox
		style.content_margin_right = style.get_content_margin(SIDE_RIGHT) + 18
		button.add_theme_stylebox_override(state, style)
	button.remove_meta("unused_warning_refresh_pending")
	button.theme_changed.connect(on_theme_changed)
