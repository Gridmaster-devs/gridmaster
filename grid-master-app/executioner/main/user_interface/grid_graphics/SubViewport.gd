class_name GridGraphicsViewport
extends SubViewport
## Class that represents the Grid Graphics viewport

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


## Resizes the viewport to be of the specified size
## Called by the Grid Graphics object at the start
func resize(new_size : Vector2) -> void:
	self.size = new_size


# TODO: I don't think this needs to be called every frame.
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# self.size = Vector2i(control_ref.size)
	pass
