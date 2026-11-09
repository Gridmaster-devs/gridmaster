class_name EditorThemes
extends RefCounted
## Switches the editor between dark and light mode.
##
## Many scenes assign editor-theme.tres directly on their nodes, so a theme set
## on a parent would not reach them. They all share one loaded instance though,
## so that instance is rewritten in place and every node updates at once.

const ACTIVE: Theme = preload("res://editor/themes/editor-theme.tres")
const LIGHT: Theme = preload("res://editor/themes/editor-theme-light.tres")

const _PLACEHOLDER_DARK: Image = preload("res://editor/editors/unit_editor/placeholder.jpg")
const _PLACEHOLDER_LIGHT: Image = preload("res://editor/editors/unit_editor/placeholder_light.jpg")

const _SETTINGS_PATH := "user://editor_settings.cfg"
const _SETTINGS_SECTION := "appearance"
const _SETTINGS_KEY := "light_mode"

## ACTIVE's original dark contents, kept because apply() overwrites ACTIVE.
static var _dark: Theme = ACTIVE.duplicate()
static var _light_mode := false
static var _dark_placeholder := ImageTexture.create_from_image(_PLACEHOLDER_DARK)
static var _light_placeholder := ImageTexture.create_from_image(_PLACEHOLDER_LIGHT)


static func apply(light_mode: bool) -> void:
	_light_mode = light_mode
	# Cleared first so items only one of the themes defines don't carry over.
	ACTIVE.clear()
	ACTIVE.merge_with(LIGHT if light_mode else _dark)


## The image to show where a unit has no picture of its own.
static func placeholder() -> Texture2D:
	return _light_placeholder if _light_mode else _dark_placeholder


## The image to store on a unit with no picture. It is the same in both modes
## so saved units, and the game that loads them, don't depend on the theme.
static func saved_placeholder() -> Texture2D:
	return _dark_placeholder


static func is_placeholder(texture: Texture2D) -> bool:
	if texture == null:
		return false
	if texture == _dark_placeholder or texture == _light_placeholder:
		return true
	# Units loaded from disk hold their own copy of the dark image.
	if texture.get_size() != Vector2(_PLACEHOLDER_DARK.get_size()):
		return false
	var image := texture.get_image()
	return image != null and image.get_data() == _PLACEHOLDER_DARK.get_data()


static func load_light_mode() -> bool:
	var settings := ConfigFile.new()
	settings.load(_SETTINGS_PATH) # A missing file just means the default below.
	return settings.get_value(_SETTINGS_SECTION, _SETTINGS_KEY, false)


static func save_light_mode(light_mode: bool) -> void:
	var settings := ConfigFile.new()
	settings.load(_SETTINGS_PATH) # Keeps any other settings already in the file.
	settings.set_value(_SETTINGS_SECTION, _SETTINGS_KEY, light_mode)
	var error := settings.save(_SETTINGS_PATH)
	if error != OK:
		push_warning("Could not save editor settings: %s" % error_string(error))
