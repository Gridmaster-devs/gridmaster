extends Node
## Global object (autoload) that receives messages and emits a signal
## that different message receivers (e.g. message_window) can attach to 

signal message_broadcast(message)
	
## Use this function to send messages to any receivers that subscribe to
## MessageDispatcher
func broadcast_message(message: String) -> void:
	message_broadcast.emit(message)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
