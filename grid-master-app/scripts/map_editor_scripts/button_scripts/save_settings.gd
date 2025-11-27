extends Button


@onready var parent_ref = $"../../../../.."

func _ready():
	self.pressed.connect(_on_button_pressed)


func _on_button_pressed():
	var settings = {
		"width": $"../Map dimensions/Width/HBoxContainer/LineEditWidth".text.to_int(),
		"height": $"../Map dimensions/Height/HBoxContainer/LineEditHeight".text.to_int()
	}
	print("Settings to save: ", settings)
	parent_ref.parent_ref.resize(settings["width"], settings["height"])
	
	$"../../../../..".queue_free()
