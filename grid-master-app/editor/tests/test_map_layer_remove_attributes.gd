extends GutTest

func _make_layer(tiles: Array) -> MapLayer:
	var layer := MapLayer.new(tiles.size(), 1, "__unused_texture_key__", "name")
	add_child_autofree(layer._tile_map_layer)
	for x in tiles.size():
		layer._attribute_grid.setItem(x, 0, tiles[x].duplicate(true))
	return layer

func test_required_player_and_team_leave_other_players_tile_unchanged() -> void:
	var player_a := {"name": "infantry", "unit": "infantry", "player": "A", "team": "red", "unit_texture": "shared"}
	var player_b := {"name": "infantry", "unit": "infantry", "player": "B", "team": "red", "unit_texture": "shared"}
	var other_unit_a := {"name": "cavalry", "unit": "cavalry", "player": "A", "team": "red", "unit_texture": "horse"}
	var layer := _make_layer([player_a, player_b, other_unit_a])
	var original_b: Dictionary = player_b.duplicate(true)
	var library_item : Dictionary[String, Variant] = {"unit": "infantry", "player": "A", "team": "red", "unit_texture": "regenerated"}
	var ownership : Dictionary[String, Variant] = {"player": "A", "team": "red"}

	layer.remove_attributes(library_item, "unit", "infantry", ownership)

	assert_eq(layer._attribute_grid.getItem(0, 0), {"name": "infantry", "unit_texture": "shared"})
	assert_eq(layer._attribute_grid.getItem(1, 0), original_b)
	assert_eq(layer._attribute_grid.getItem(2, 0), other_unit_a)

func test_required_team_prevents_removing_same_player_other_team() -> void:
	var red_unit := {"unit": "infantry", "player": "A", "team": "red", "unit_texture": "red"}
	var blue_unit := {"unit": "infantry", "player": "A", "team": "blue", "unit_texture": "blue"}
	var layer := _make_layer([red_unit, blue_unit])

	layer.remove_attributes({"unit": "infantry", "player": "A", "team": "red", "unit_texture": "red"}, "unit", "infantry", {"player": "A", "team": "red"})

	assert_eq(layer._attribute_grid.getItem(0, 0), {})
	assert_eq(layer._attribute_grid.getItem(1, 0), blue_unit)

func test_generic_removal_without_required_attributes_keeps_legacy_matching() -> void:
	var matching: Dictionary[String, Variant] = {"name": "forest", "movement": 2, "texture": "woods"}
	var other := {"name": "plain", "movement": 2, "texture": "plain"}
	var layer := _make_layer([matching, other])
	var library_item: Dictionary[String, Variant] = matching.duplicate()

	layer.remove_attributes(library_item, "name", "forest")

	assert_eq(layer._attribute_grid.getItem(0, 0), {})
	assert_eq(layer._attribute_grid.getItem(1, 0), other)
