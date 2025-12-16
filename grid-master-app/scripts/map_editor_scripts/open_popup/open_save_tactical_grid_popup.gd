extends Node

@onready var parent_ref = $"../../../../../../.."

func _ready() -> void:
	self.pressed.connect(_on_button_pressed)

	
func _on_button_pressed():
	if parent_ref.cur_gw == parent_ref.GridView.TACTICAL: 
		var save_tactical_grid_popup = preload("res://editors/map_editor/popup_windows/tactical_grid_save_popup.tscn").instantiate()
		get_tree().get_root().add_child(save_tactical_grid_popup)
		save_tactical_grid_popup.name = "save_tactical_grid_poup"
		save_tactical_grid_popup.parent_ref = parent_ref
		save_tactical_grid_popup.set_tactical_grid_name(parent_ref.cur_tactical_grid_name)
	elif parent_ref.cur_gw == parent_ref.GridView.STRATEGIC: 
		parent_ref.save_dialog.visible = true
	
	
