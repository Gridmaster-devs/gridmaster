extends Node
## Global object that receives messages and forwards them to a message window.

signal message_broadcast
	
func broadcast_message(message: String) -> void:
	message_broadcast.emit(message)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
