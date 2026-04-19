extends Node
class_name TextureSelecter

@onready var _open_color_picker_button = $OpenColorPickerButton
@onready var _open_image_drag_and_drop_button = $OpenTexturePickerButton
@onready var _texture_preview = $TexturePreview

var _texture: Texture2D = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_open_color_picker_button.pressed.connect(_open_color_picker)
	_open_image_drag_and_drop_button.pressed.connect(_open_dragndrop)
	
func _on_color_picker_save(texture: Texture2D) -> void: 
	_texture = texture
	_texture_preview.texture = texture
	
##Getters
func get_texture() -> Texture2D:
	return _texture
	

func _open_color_picker() -> void: 
	var color_picker: TextureColorPicker = preload("res://common/popups/color_picker.tscn").instantiate()
	color_picker.add_to_tree()
	color_picker.texture_saved.connect(_on_color_picker_save)	
	
func _open_dragndrop() -> void: 
	var drag_n_drop: ImageDragAndDropPopup = preload("res://common/popups/image_drag_and_drop.tscn").instantiate()
	drag_n_drop.add_to_tree()
	drag_n_drop.texture_saved.connect(_on_color_picker_save)
	
	
	
	
