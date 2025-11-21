extends Node

@export var load_dialog : FileDialog
@export var image_picker : FileDialog
@export var unit_resource_base : Resource
@export var unit_name : LineEdit
@export var unit_description : TextEdit
@export var image_container : TextureRect

func _save_unit() -> void:
	var unit = UnitResource.new()
	unit.description = unit_description.text
	unit.name = unit_name.text
	unit.image = image_container.texture
	ResourceSaver.save(unit, "user://units/{name}.tres".format({"name" : unit_name.text}))
	
func _show_load_dialog() -> void:
	load_dialog.show()
	
func _load_unit(path : String) -> void:
	var data = ResourceLoader.load(path) as UnitResource
	unit_name.text = data.name
	unit_description.text = data.description
	image_container.texture = data.image
	
func _pick_image() -> void:
	image_picker.show()

func _set_image(path: String) -> void:
	var image = Image.load_from_file(path)
	image_container.texture = ImageTexture.create_from_image(image)
	
func _init() -> void:
	if not DirAccess.dir_exists_absolute("user://units"):
		DirAccess.make_dir_absolute("user://units")

func _ready() -> void:
	load_dialog.root_subfolder = "units"
