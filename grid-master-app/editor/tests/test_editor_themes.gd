extends GutTest

const DATA_TYPES: Array[int] = [
	Theme.DATA_TYPE_COLOR,
	Theme.DATA_TYPE_CONSTANT,
	Theme.DATA_TYPE_FONT,
	Theme.DATA_TYPE_FONT_SIZE,
	Theme.DATA_TYPE_ICON,
	Theme.DATA_TYPE_STYLEBOX,
]


func before_each() -> void:
	EditorThemes.apply(false)


func after_each() -> void:
	EditorThemes.apply(false)


func test_light_theme_defines_every_dark_item() -> void:
	for type_name in EditorThemes.ACTIVE.get_type_list():
		for data_type in DATA_TYPES:
			for item_name in EditorThemes.ACTIVE.get_theme_item_list(data_type, type_name):
				assert_true(
					EditorThemes.LIGHT.has_theme_item(data_type, item_name, type_name),
					"Light theme is missing %s/%s" % [type_name, item_name]
				)


func test_apply_light_replaces_colors() -> void:
	EditorThemes.apply(true)
	assert_eq(
		EditorThemes.ACTIVE.get_color("font_color", "Label"),
		EditorThemes.LIGHT.get_color("font_color", "Label")
	)


func test_apply_keeps_type_variations() -> void:
	EditorThemes.apply(true)
	assert_eq(EditorThemes.ACTIVE.get_type_variation_base("PrimaryButton"), &"Button")


func test_switching_back_restores_dark_theme() -> void:
	var dark_color := EditorThemes.ACTIVE.get_color("font_color", "Label")
	EditorThemes.apply(true)
	EditorThemes.apply(false)
	assert_eq(EditorThemes.ACTIVE.get_color("font_color", "Label"), dark_color)


func test_switching_back_drops_light_only_items() -> void:
	EditorThemes.apply(true)
	assert_true(EditorThemes.ACTIVE.has_stylebox("grabber", "VScrollBar"))
	EditorThemes.apply(false)
	assert_false(EditorThemes.ACTIVE.has_stylebox("grabber", "VScrollBar"))


func test_placeholder_follows_mode() -> void:
	var dark_placeholder := EditorThemes.placeholder()
	EditorThemes.apply(true)
	assert_ne(EditorThemes.placeholder(), dark_placeholder)
	assert_true(EditorThemes.is_placeholder(EditorThemes.placeholder()))


func test_saved_placeholder_is_the_same_in_both_modes() -> void:
	var saved := EditorThemes.saved_placeholder()
	EditorThemes.apply(true)
	assert_eq(EditorThemes.saved_placeholder(), saved)


func test_reloaded_copy_of_placeholder_is_recognised() -> void:
	var copy := ImageTexture.create_from_image(EditorThemes.saved_placeholder().get_image())
	assert_true(EditorThemes.is_placeholder(copy))


func test_custom_image_is_not_a_placeholder() -> void:
	var image := Image.create_empty(8, 8, false, Image.FORMAT_RGB8)
	assert_false(EditorThemes.is_placeholder(ImageTexture.create_from_image(image)))
