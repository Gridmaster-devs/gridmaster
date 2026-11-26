extends GutTest

var game_state : GameState
var game_def: GameDefinition
var game_manager: GameDataManager
var player_id: int


func before_each():
	game_state = GameState.new({}, 0, 0)
	game_def = GameDefinition.new()
	game_manager = GameDataManager.new(game_state, game_def, ClientAttributes.new())
	game_def.resources = ["Gold", "Wood"]

	var team_id: int = game_def.add_team("Team 1", Color(0, 0, 0), [])
	player_id = game_def.add_player("Player 1", team_id, false)


#Helper function to add a unit that consumes and produces resources
func add_unit(consumed: String, consumed_amount: int, produced: String, produced_amount: int) -> Unit:
	var unit_type: UnitType = UnitType.debugType()
	var cp: ConsumeProduce = ConsumeProduce.new()
	cp.consumed_resource = consumed
	cp.consumed_amount = consumed_amount
	cp.produced_resource = produced
	cp.produced_amount = produced_amount
	unit_type.consume_produce_actions.append(cp)
	return game_state.addUnit(unit_type, Vector2i(0, 0), game_def.players.get(player_id))

#Test that players start with none of every resource
func test_players_start_with_no_resources():
	assert_eq(game_manager.get_player_resources(player_id), {"Gold": 0, "Wood": 0})

#Test that a unit that consumes nothing produces every turn
func test_unit_produces_resource():
	add_unit(ConsumeProduce.NO_RESOURCE, 0, "Gold", 2)
	game_manager.process_resources()
	game_manager.process_resources()
	assert_eq(game_manager.get_player_resources(player_id)["Gold"], 4)

#Test that a unit consumes a resource to produce another
func test_unit_consumes_resource():
	game_manager.set_resource_amount(player_id, "Wood", 3)
	add_unit("Wood", 2, "Gold", 1)
	game_manager.process_resources()
	assert_eq(game_manager.get_player_resources(player_id), {"Gold": 1, "Wood": 1})

#Test that a unit doesn't produce if the player can't pay for it
func test_unit_does_not_produce_without_resources():
	game_manager.set_resource_amount(player_id, "Wood", 1)
	add_unit("Wood", 2, "Gold", 1)
	game_manager.process_resources()
	assert_eq(game_manager.get_player_resources(player_id), {"Gold": 0, "Wood": 1})

#Test that resources the game doesn't define are ignored
func test_undefined_resource_is_ignored():
	add_unit(ConsumeProduce.NO_RESOURCE, 0, "Stone", 5)
	game_manager.process_resources()
	assert_eq(game_manager.get_player_resources(player_id), {"Gold": 0, "Wood": 0})

#Test that resources are kept when the game state is copied
func test_resources_survive_deep_copy():
	game_manager.set_resource_amount(player_id, "Gold", 7)
	var copy: GameState = game_state.deep_copy()
	assert_eq(copy.get_resource_amount(player_id, "Gold"), 7)

#Helper function to create a small icon texture
func create_icon(color: Color) -> Texture2D:
	var img: Image = Image.create_empty(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)

#Test that resource icons are kept when a game file is saved and loaded
func test_resource_icons_survive_save_and_load():
	var game_resource: GameDefinitionResource = GameDefinitionResource.new()
	game_resource.save_resources(["Gold", "Wood"] as Array[String])
	game_resource.save_resource_icons({"Gold": create_icon(Color.YELLOW)} as Dictionary[String, Texture2D])
	var path: String = "user://test_resource_icons.tres"
	assert_eq(ResourceSaver.save(game_resource, path), OK)
	
	var loaded := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as GameDefinitionResource
	var icons: Dictionary[String, Texture2D] = loaded.load_resource_icons()
	assert_eq(icons.keys(), ["Gold"])
	assert_eq(icons["Gold"].get_image().get_pixel(0, 0), Color.YELLOW)
	DirAccess.remove_absolute(path)

#Test that games made before resource icons existed load without icons
func test_old_game_has_no_resource_icons():
	var game_resource: GameDefinitionResource = GameDefinitionResource.new()
	assert_eq(game_resource.load_resource_icons(), {})

#Test that the resource bar shows one entry per resource, with the icon only where there is one
func test_resource_bar_shows_entries():
	var gui: InGameDefaultGUI = preload("res://executioner/main/game_master/gui_scenes/in_game_default_gui.tscn").instantiate()
	add_child_autofree(gui)
	gui.set_resources({"Gold": 3, "Wood": 1} as Dictionary[String, int], {"Gold": create_icon(Color.YELLOW)} as Dictionary[String, Texture2D])
	await wait_process_frames(1)
	
	var entries: Array[Node] = gui._resources_container.get_children()
	assert_eq(entries.size(), 2)
	assert_eq(entries[0]._amount_label.text, "3")
	assert_eq(entries[0]._name_label.text, "GOLD")
	assert_true(entries[0]._icon_rect.visible)
	assert_false(entries[1]._icon_rect.visible)

#Test that the resource bar hides the resources if the game has none
func test_resource_bar_hidden_without_resources():
	var gui: InGameDefaultGUI = preload("res://executioner/main/game_master/gui_scenes/in_game_default_gui.tscn").instantiate()
	add_child_autofree(gui)
	gui.set_resources({} as Dictionary[String, int], {} as Dictionary[String, Texture2D])
	assert_false(gui._resources_container.visible)

#Test that units of the same type and owner get one combined message in the log
func test_resource_messages_are_combined_per_unit_type():
	game_manager.set_resource_amount(player_id, "Wood", 5)
	for i in 3:
		add_unit("Wood", 2, "Gold", 4)
	watch_signals(MessageDispatcher)
	game_manager.process_resources()
	assert_signal_emit_count(MessageDispatcher, "message_broadcast", 1)
	assert_signal_emitted_with_parameters(MessageDispatcher, "message_broadcast", ["[Player 1] Test unit x3: consumed 4 Wood, produced 8 Gold, 1 lacked Wood."])

#Test that units without resource actions don't get a message
func test_no_resource_message_without_resource_actions():
	add_unit(ConsumeProduce.NO_RESOURCE, 0, ConsumeProduce.NO_RESOURCE, 0)
	watch_signals(MessageDispatcher)
	game_manager.process_resources()
	assert_signal_not_emitted(MessageDispatcher, "message_broadcast")
