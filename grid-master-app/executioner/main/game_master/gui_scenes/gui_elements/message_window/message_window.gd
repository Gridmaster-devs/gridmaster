class_name MessageWindow
extends FoldableContainer
## Class that displays a message window that shows messages
## broadcast to it via a signal

## How many messages are kept in the window's history at once
var MAX_MESSAGES = 10

var message_queue: Array[Label]

@onready var message_container = $ScrollContainer/MarginContainer/MessageContainer
var label_scene : PackedScene = preload("res://executioner/main/game_master/gui_scenes/gui_elements/message_window/message.tscn")

func _ready() -> void:
	MessageDispatcher.message_broadcast.connect(_on_message_broadcast)
	
## callback for attaching to a message_broadcast signal. When a signal
## is emitted, it calls the internal functions to place the message
## in the message queue (also graphically).
func _on_message_broadcast(message: String) -> void:
	_enqueue_message(message)
	
func _enqueue_message(message: String) -> void:
	var label : Label = label_scene.instantiate()
	label.text = message
	
	if message_queue.size() == MAX_MESSAGES:
		_dequeue_message()
		
	message_queue.push_back(label)
	message_container.add_child(label)
	
func _dequeue_message():
	var oldest_message = message_queue.pop_front()
	oldest_message.queue_free()
