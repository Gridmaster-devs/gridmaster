class_name MessageWindow
extends FoldableContainer

var MAX_MESSAGES = 10

var message_queue: Array[Label]

var message_container

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	message_container = get_node("ScrollContainer/VBoxContainer")
	
func _on_message_broadcast(message: String) -> void:
	_enqueue_message(message)
	
func _enqueue_message(message: String) -> void:
	var label = Label.new()
	label.text = message
	if message_queue.size() == MAX_MESSAGES:
		_dequeue_message()
	message_queue.push_back(label)
	message_container.add_child(label)
	
func _dequeue_message():
	var oldest_message = message_queue.pop_front()
	oldest_message.queue_free()
