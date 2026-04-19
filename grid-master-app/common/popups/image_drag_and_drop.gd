extends PopupWindow
class_name ImageDragAndDropPopup

@onready var _image_cont: TextureRect = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/PanelContainer/TextureRect
@onready var _cancel_button: Button = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Cancel
@onready var _save_button: Button = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Save

var _has_texture = false
##signals
signal texture_saved(texture: Texture2D)

func _ready() -> void :
	_cancel_button.pressed.connect(_cancel)
	_save_button.pressed.connect(_save)
	get_viewport().connect("files_dropped", Callable(self, "_on_files_dropped"))
	
func _init() -> void: 
	set_popup_name("drag_and_drop")

func _on_files_dropped(files: Array) -> void:
	for path in files:
		if _is_valid_image_file(path):
			_handle_file(path)

func _is_valid_image_file(path: String) -> bool:
	var ext = path.get_extension().to_lower()
	return ext in ["png", "jpg", "jpeg"]

func _handle_file(path: String) -> void:
	var img = Image.new()
	var err = img.load(path)
	if err != OK:
		return
	img.resize(Global.tile_width, Global.tile_height)
	_image_cont.texture = ImageTexture.create_from_image(img)
	_has_texture = true

func _get_default_img() -> Texture2D: 
	var img: Image = preload("res://editor/editors/unit_editor/placeholder.jpg")
	if not img or img.get_size() == Vector2i.ZERO:
		var backup_img = Image.create_empty(Global.tile_width, Global.tile_height, false, Image.FORMAT_RGBA8)
		backup_img.fill(Color(0.822, 0.001, 0.871, 1.0))
		img = backup_img
	return ImageTexture.create_from_image(img)


func _save() -> void: 
	if _has_texture and _image_cont.texture != null: 
		texture_saved.emit(_image_cont.texture)
	remove_from_tree()
	
func _cancel() -> void: 
	remove_from_tree()


#util
func _get_opaqued(inc_img: Image) -> Texture2D: 
	var img = Image.create(Global.tile_width, Global.tile_height, false, Image.FORMAT_RGBA8)
	for x in range(img.get_width()):
		for y in range(img.get_height()):
			img.set_pixel(x, y, Color(0, 0, 0, 0))
			var buffer_horizontal = (Global.tile_width - Global.unit_width ) / 2.0
			var buffer_vertical = (Global.tile_height - Global.unit_height ) / 2.0
			var left = buffer_horizontal
			var right = Global.tile_width - buffer_horizontal
			var top = buffer_vertical
			var bottom = Global.tile_height - buffer_vertical
			if x > left and x < right and y > top and y < bottom: 
				if x < inc_img.get_width() and y < inc_img.get_height():
					img.set_pixel(x, y, inc_img.get_pixel(x, y))
	return ImageTexture.create_from_image(img)
