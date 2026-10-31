extends GutTest

const MAP_PAINTER_SCENE: PackedScene = preload("res://editor/editors/map_editor_refactor/user_interfaces/map_painter.tscn")

func _make_painter_with_library(item_count: int) -> MapPainter:
	var painter := MAP_PAINTER_SCENE.instantiate() as MapPainter
	add_child_autofree(painter)
	var layer := MapLayer.new(item_count, 1, "__unused_texture_key__", "unit")
	add_child_autofree(layer._tile_map_layer)
	painter.layers.append(layer)
	painter.add_library("Test library", MapAttributes.STRATEGIC_TILE_LIB_ADD,
		MapAttributes.STRATEGIC_TILE_LIB_ADD, "missing_preview", "unit", 0)
	var items: Array = []
	for index in item_count:
		var unit_type := "unit_%d" % index
		var item: Dictionary[String, Variant] = {"unit": unit_type, "marker": "owned_by_library"}
		items.append(item)
		layer._attribute_grid.setItem(index, 0, item.duplicate(true))
	painter._lib_items_data["Test library"] = items
	return painter

func test_remove_library_clears_zero_to_three_items_and_is_idempotent() -> void:
	for item_count in range(4):
		var painter := _make_painter_with_library(item_count)
		var layer: MapLayer = painter.layers[0]
		autoqfree(painter._paint_libraries["Test library"])

		painter.remove_library("Test library")

		assert_false(painter._paint_libraries.has("Test library"), "library removed for %d items" % item_count)
		assert_false(painter._lib_items_data.has("Test library"), "item data removed for %d items" % item_count)
		for index in item_count:
			assert_eq(layer._attribute_grid.getItem(index, 0), {}, "map tile cleared for item %d" % index)

		painter.remove_library("Test library")
		assert_false(painter._paint_libraries.has("Test library"), "second removal is harmless")
