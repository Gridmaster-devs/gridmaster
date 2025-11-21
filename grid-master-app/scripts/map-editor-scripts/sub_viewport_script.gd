extends SubViewport


# Called when the node enters the scene tree for the first time.

@onready var control_ref = $"../.."


func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	self.size = Vector2i(control_ref.size)
