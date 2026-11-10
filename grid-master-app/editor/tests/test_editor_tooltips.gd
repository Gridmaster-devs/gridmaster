extends GutTest

func test_registry_and_warning_set() -> void:
	var count := 0
	var warnings := 0
	for context in EditorTooltips.TEXT:
		for key in EditorTooltips.TEXT[context]:
			count += 1
			var tip := EditorTooltips.get_tooltip(context, key)
			assert_false(tip.is_empty())
			for status in ["Currently used", "Display only", "Editor only"]:
				assert_false(status in tip)
			if EditorTooltips.has_warning(context, key):
				warnings += 1
	assert_eq(count, 77)
	assert_eq(warnings, 11)
	assert_eq(EditorTooltips.WARNING_TEXT, "Not yet used in gameplay")
	assert_eq(EditorTooltips.get_tooltip("unit", "health"), "How much damage the unit can take before being destroyed.")
	assert_eq(EditorTooltips.get_tooltip("game", "player_key_unit"), "The unit type this player must keep alive to avoid elimination. Leave blank to count any surviving unit.")
	assert_eq(EditorTooltips.get_tooltip("unit", "missing"), "")
	assert_eq(EditorTooltips.get_tooltip("map", "name"), "")
	assert_false(EditorTooltips.has_warning("unit", "health"))
	assert_false(EditorTooltips.has_warning("unit", "morale"))
	assert_false(EditorTooltips.has_warning("map", "save_map"))

func test_label_warning_is_separate_and_idempotent() -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	var input := LineEdit.new()
	label.text = "Producible"
	input.text = "preserved"
	row.add_child(label)
	row.add_child(input)
	add_child_autofree(row)
	TooltipHelper.apply(label, "unit", "is_producible_unit")
	TooltipHelper.apply(label, "unit", "is_producible_unit")
	assert_eq(label.tooltip_text, EditorTooltips.get_tooltip("unit", "is_producible_unit"))
	assert_ne(label.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(input.tooltip_text, "")
	assert_eq(input.text, "preserved")
	assert_eq(label.get_child_count(), 1)
	assert_eq(label.get_child(0).tooltip_text, EditorTooltips.WARNING_TEXT)
	assert_eq(row.get_child(1), input)

func test_action_fields_have_separate_warnings() -> void:
	var panel = load("res://editor/editors/unit_editor/Action panels/ConsumeProducePanel.tscn").instantiate()
	add_child_autofree(panel)
	for group in ["Consumes", "Produces"]:
		var row = panel.get_node(group)
		var count := 0
		for child in row.get_children():
			if child is Label and child.has_node("UnusedFeatureWarning"):
				count += 1
		assert_eq(count, 2)
		assert_eq(row.get_node("ResourceAmount").tooltip_text, "")
		assert_eq(row.get_node("ResourceName").tooltip_text, "")

func test_generated_team_and_player_rows_use_context() -> void:
	var team = load("res://editor/editors/game_editor/team_ui.tscn").instantiate()
	var player = load("res://editor/editors/game_editor/player_ui.tscn").instantiate()
	add_child_autofree(team)
	add_child_autofree(player)
	team.init_units(["Infantry"])
	player.init_teams(["Blue"])
	var team_label: Label = team._unit_uis["Infantry"].get_node("TeamUnitType/HBoxContainer/Label")
	var player_label: Label = player._team_uis["Blue"].get_node("TeamUnitType/HBoxContainer/Label")
	assert_eq(team_label.tooltip_text, EditorTooltips.get_tooltip("game", "team_unit_selection"))
	assert_true(team_label.has_node("UnusedFeatureWarning"))
	assert_eq(player_label.tooltip_text, EditorTooltips.get_tooltip("game", "player_team"))
	assert_false(player_label.has_node("UnusedFeatureWarning"))

func test_generated_terrain_hiding_field() -> void:
	var popup = load("res://editor/editors/map_editor_refactor/popup_windows/new_tile_popup.tscn").instantiate()
	add_child_autofree(popup)
	var attributes: Dictionary[String, Variant] = {"hiding": 0, "movement": 0}
	popup.init(attributes, "Terrain")
	var rows = popup.get_node("EditorPanel/TopVBox/ScrollContainer/ContentsVBox/AttributesVbox")
	var hiding: Label = rows.get_child(1).get_child(0)
	var movement: Label = rows.get_child(2).get_child(0)
	assert_eq(hiding.tooltip_text, EditorTooltips.get_tooltip("map", "tile.hiding"))
	assert_true(hiding.has_node("UnusedFeatureWarning"))
	assert_false(movement.has_node("UnusedFeatureWarning"))
	assert_eq(popup.get_ui_element("hiding").tooltip_text, "")

func test_editor_scenes_instantiate() -> void:
	for path in ["res://editor/editors/unit_editor/UnitEditor.tscn", "res://editor/editors/game_editor/GameEditor.tscn", "res://editor/editors/map_editor_refactor/map_editor.tscn"]:
		var editor = load(path).instantiate()
		add_child_autofree(editor)
		assert_not_null(editor)

func test_exact_registry_copy_and_warning_keys() -> void:
	var expected = {
	  "unit": {
	    "name": "The name shown for this unit type.",
		    "texture": "The image used to represent this unit.",
	    "movement_type": "How far the unit can move each turn. Different terrain costs different amounts of movement points, and faster units move first.",
	    "movement_speed": "How many movement points the unit has and when it acts each turn.",
	    "capturable": "Whether this unit can be captured by another player.",
	    "is_producible_unit": "Whether this unit can be produced by other units.",
	    "production_cost": "How many turns it takes to produce this unit.",
	    "is_production_unit": "Whether this unit can produce other units.",
	    "producible_units": "Which unit types this unit can produce.",
	    "health": "How much damage the unit can take before being destroyed.",
	    "morale": "The unit's starting morale.",
	    "victory_points": "How many victory points this unit is worth.",
	    "attack": "How much damage this unit deals when it hits.",
	    "armor_piercing": "How much armor this unit can penetrate.",
	    "accuracy": "How likely this unit is to hit its target.",
	    "attack_range": "How far this unit can attack (in tiles).",
	    "armor": "How much armor protects this unit from attacks.",
	    "evasion": "How likely this unit is to dodge an attack.",
	    "vision_range": "How far the unit will see (in tiles).",
	    "perception": "How well this unit can detect hidden enemies.",
	    "action_name": "The name of this action.",
	    "action_type": "The kind of action this unit can perform.",
	    "consumed_resource": "Which resource this action consumes.",
	    "consumed_amount": "How much of the resource this action consumes.",
	    "produced_resource": "Which resource this action produces.",
	    "produced_amount": "How much of the resource this action produces.",
	    "unit_list": "Choose a unit to view or edit.",
	    "add_unit": "Create a new unit type.",
	    "remove_unit": "Remove the selected unit type.",
	    "save_unit": "Save the selected unit to a file.",
	    "load_unit": "Load a unit from a file.",
	    "add_action": "Add an action to this unit.",
	    "remove_action": "Remove this action from the unit.",
	    "producible_units_add": "Add the selected unit type to the production list.",
	    "producible_units_remove": "Remove this unit type from the production list."
	  },
	  "map": {
	    "width": "How many tiles wide the map is.",
	    "height": "How many tiles tall the map is.",
	    "map_name": "The name shown for this map.",
	    "save_name": "The name to use when saving this map.",
	    "tile.name": "The name of this terrain type.",
	    "tile.protection": "How much this terrain reduces damage to defending units.",
	    "tile.movement": "How many movement points it costs to enter this terrain.",
	    "tile.hiding": "How much concealment this terrain provides.",
	    "tile.texture": "The image used to display this terrain.",
	    "save_map": "Save the current map.",
	    "load_map": "Load a previously saved map.",
	    "map_mode": "Switch between strategic and tactical maps.",
	    "save_name_confirm": "Save the map with the chosen name.",
	    "tactical_map": "The tactical map associated with this location.",
	    "tactical_map_thumbnail": "The preview image for this tactical map."
	  },
	  "painter": {
	    "settings": "Change the map size and name.",
	    "erase": "Erase tiles by clicking or dragging on the map.",
	    "interact": "Click a tile to view its properties.",
	    "library_tile": "Choose what to paint onto the map.",
	    "new_library_tile": "Create a new tile type.",
	    "remove_library_tile": "Remove the selected tile type.",
	    "choose_color": "Use a solid color for this tile.",
	    "choose_image": "Choose an image for this tile.",
	    "crop_image": "Crop the selected tile image.",
	    "tile_description_value": "The properties of the selected tile.",
	    "tile_create_save": "Add this tile type to the library.",
	    "tile_create_cancel": "Close without adding the tile.",
	    "settings_save": "Apply these map settings.",
	    "settings_cancel": "Close without applying changes."
	  },
	  "game": {
	    "game_name": "The name of your game.",
	    "team_name": "The name of this team.",
	    "team_color": "The color used to identify this team and its units.",
	    "team_unit_selection": "Choose which unit types are available to this team.",
	    "player_name": "The name of this player.",
	    "player_team": "Choose which team this player belongs to.",
	    "player_key_unit": "The unit type this player must keep alive to avoid elimination. Leave blank to count any surviving unit.",
	    "combat_rounds": "How many rounds of attacks can occur in one fight.",
	    "save_game": "Save this game setup to a file.",
	    "load_game": "Load a saved game setup.",
	    "new_team": "Add a new team.",
	    "new_player": "Add a new player.",
	    "unit_placement": "Select a unit, then click the map to place it."
	  }
	}
	assert_eq(EditorTooltips.TEXT, expected)
	assert_eq(EditorTooltips.WARNINGS, {"unit": ["is_producible_unit", "action_name", "action_type", "consumed_resource", "consumed_amount", "produced_resource", "produced_amount"], "map": ["tile.hiding", "tactical_map"], "painter": ["crop_image"], "game": ["team_unit_selection"]})

func test_unit_description_has_no_added_label_or_tooltip() -> void:
	var panel = load("res://editor/editors/unit_editor/UnitInfoPanel.tscn").instantiate()
	add_child_autofree(panel)
	var row = panel.get_node("TopVBox/PanelContainer/ContentsVBox/HBoxContainer")
	assert_eq(row.get_child_count(), 2)
	assert_eq(panel.description_box.tooltip_text, "")
