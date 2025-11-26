extends Button


func _ready():
	self.pressed.connect(_on_button_pressed)


func _on_button_pressed():
	# collect the values from the settings UI
	var settings = {
		"width": $"../Map dimensions/Width/HBoxContainer/LineEditWidth".text.to_int(),
		"height": $"../Map dimensions/Height/HBoxContainer/LineEditHeight".text.to_int()
	}
	print("Settings to save: ", settings)

	# close the settings window
	$"../../../../..".queue_free()
