class_name UnitInfoPanel
extends PanelContainer

var unit_editor : UnitEditor
@onready var save_button = $TopVBox/PanelContainer/ContentsVBox/HBoxContainer/VBoxContainer/Buttons/SaveButton
@onready var load_button = $TopVBox/PanelContainer/ContentsVBox/HBoxContainer/VBoxContainer/Buttons/LoadButton
@onready var name_line : LineEdit = $TopVBox/PanelContainer/ContentsVBox/NameLine
@onready var description_box = $TopVBox/PanelContainer/ContentsVBox/HBoxContainer/ScrollContainer/Description
@onready var _unit_image_cont: TextureRect = $TopVBox/PanelContainer/ContentsVBox/HBoxContainer/VBoxContainer/PanelContainer/ImageContainer


func unit_name_changed(new_text : String):
	unit_editor.update_name_in_tree(new_text)
	
func save_to_resource(unit_resource : UnitResource):
	if (unit_resource != null):
		var unit_name = name_line.text
		if (unit_name == ""):
			unit_resource.set_attribute("name", "")
		else:
			unit_resource.set_attribute("name", unit_name)
			
		var unit_description = description_box.text
		unit_resource.set_attribute("description", unit_description)
		unit_resource.set_attribute("texture", _unit_image_cont.texture)

func load_from_resource(unit_resource : UnitResource):
	if (unit_resource != null):
		var unit_name = unit_resource.get_attribute_value("name")
		if (unit_name == "" or unit_name == null):
			name_line.text = ""
		else:
			name_line.text = unit_name
			
		var unit_description = unit_resource.get_attribute_value("description")
		if (unit_description == null):
			description_box.text = ""
		else:
			description_box.text = unit_description
		
		var unit_texture = unit_resource.get_attribute_value("texture")
		if (unit_texture == null):
			_unit_image_cont.texture = _get_default_img()
		else:
			_unit_image_cont.texture = unit_texture
			
func get_save_button() -> Button:
	return save_button
	
func get_load_button() -> Button:
	return load_button
	
func reset():
	name_line.text = ""
	description_box.text = ""
	_unit_image_cont.texture = _get_default_img()
	
func link_unit_editor(ue : UnitEditor):
	unit_editor = ue
	unit_editor.save_to_resource.connect(save_to_resource)
	unit_editor.load_from_resource.connect(load_from_resource)
	name_line.text_changed.connect(unit_name_changed)
		
func _ready():
	self.add_to_group("info_panel")
	get_viewport().connect("files_dropped", Callable(self, "_on_files_dropped"))

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
	_unit_image_cont.texture = ImageTexture.create_from_image(img)

func _get_default_img() -> Texture2D: 
	var img: Image = preload("res://editor/editors/unit_editor/placeholder.jpg")
	if not img or img.get_size() == Vector2i.ZERO:
		var backup_img = Image.create_empty(Global.tile_width, Global.tile_height, false, Image.FORMAT_RGBA8)
		backup_img.fill(Color(0.822, 0.001, 0.871, 1.0))
		img = backup_img
	return ImageTexture.create_from_image(img)



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









#
