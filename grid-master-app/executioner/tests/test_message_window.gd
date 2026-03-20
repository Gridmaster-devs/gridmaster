extends GutTest

var message_window_scene = load("res://executioner/main/game_master/gui_scenes/gui_elements/message_window/message_window.tscn")

@onready var root = get_tree().root

func before_each():
	var message_window = message_window_scene.instantiate()
	root.add_child(message_window)
	
func after_each():
	var message_window = root.find_child("MessageWindow", true, false )
	message_window.free()

func test_receives_signal_from_Dispatcher():
	MessageDispatcher.broadcast_message("Test message")
	
	var message_window = root.find_child("MessageWindow", true, false )
	
	assert_eq(message_window.message_queue[0].text, "Test message")
	
func test_only_keeps_message_up_to_max():
	var message_window = root.find_child("MessageWindow", true, false )

	MessageDispatcher.broadcast_message("Message that should be removed")
	for i in range(message_window.MAX_MESSAGES):
		MessageDispatcher.broadcast_message("Test message")
		
	for m in message_window.message_queue:
		assert_ne(m.text, "Message that should be removed")
