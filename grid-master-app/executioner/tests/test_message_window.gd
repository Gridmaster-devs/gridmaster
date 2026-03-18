extends GutTest

var message_window_scene = load("res://executioner/main/game_master/gui_scenes/gui_elements/message_window/message_window.tscn")
var message_window = message_window_scene.instantiate()

func test_receives_signal_from_Dispatcher():
	MessageDispatcher.broadcast_message("Test message")
	
	await wait_for_signal(MessageDispatcher.message_broadcast, 10)
	
	print(message_window.message_queue)
	#assert_eq(message_window.message_queue[0].text, "Test message") 
