extends Node
class_name TextureSelecter

@onready var _open_color_picker_button = $OpenTexturePickerButton
@onready var _texture_preview = $TexturePreview

var _texture: Texture2D = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_open_color_picker_button.pressed.connect(_open_color_picker)
	
func _on_color_picker_save(texture: Texture2D) -> void: 
	_texture = texture
	_texture_preview.texture = texture
	
##Getters
func get_texture() -> Texture2D:
	return _texture
	

func _open_color_picker() -> void: 
	var color_picker = preload("res://editor/editors/map_editor_refactor/popup_windows/color_picker.tscn").instantiate()
	get_tree().call_group("map_painter_popup_manager", "add_new_popup", color_picker, color_picker.get_popup_name())
	color_picker.save_color_picker.connect(_on_color_picker_save)
