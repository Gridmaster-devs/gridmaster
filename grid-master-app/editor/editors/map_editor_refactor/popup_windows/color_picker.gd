extends PopupWindow
class_name TextureColorPicker

@onready var save_button = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/SaveButton
@onready var cancel_button = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/CancelButton
@onready var color_picker = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/ColorPicker


##signals
signal texture_saved(texture: Texture2D)
signal color_saved(color: Color)

func _init() -> void: 
	super.set_popup_name("texture_color_picker_popup")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	save_button.pressed.connect(_save)
	cancel_button.pressed.connect(_cancel)


func _get_texture() -> Texture2D: 
	var color = color_picker.color
	var img = Image.create_empty(Global.tile_width, Global.tile_height, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)

func _save() -> void: 
	texture_saved.emit(_get_texture())
	color_saved.emit(color_picker.color)
	get_tree().call_group(Global.popup_manager_group, Global.close_popup, self.get_popup_name())
	
func _cancel() -> void: 
	get_tree().call_group(Global.popup_manager_group, Global.close_popup, self.get_popup_name())
	
	
	
	
	
