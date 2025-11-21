extends Node

@export_group("File Dialogs")
@export var load_dialog : FileDialog
@export var image_picker : FileDialog

@export_group("Unit Resource")
@export var unit_resource_base : Resource

@export_category("Info")
@export var name_source : LineEdit
@export var description_source : TextEdit
@export var image_source : TextureRect

@export_category("Attributes")
@export_group("Movement")
@export var movement_type_source : PanelItem
@export var movement_speed_source : PanelItem
@export_group("Interaction")
@export var capturable_source : PanelItem
@export_group("")

@export_category("Resources")
@export_group("Vitality")
@export var health_source : PanelItem
@export var morale_source : PanelItem
@export_group("")

@export_category("Stats")
@export_group("Offensive")
@export var damage_source : PanelItem
@export var piercing_source : PanelItem
@export var accuracy_source : PanelItem
@export var reach_source : PanelItem
@export_group("Defensive")
@export var armor_source : PanelItem
@export var evasion_source : PanelItem
@export_group("Utility")
@export var perception_source : PanelItem
@export var vision_range_source : PanelItem
@export_group("Value")
@export var victory_points_source : PanelItem
@export_group("")

@export_category("Actions")
@export_group("Orders")
@export_group("")

func _save_unit() -> void:
	var unit = UnitResource.new()
	unit.name = name_source.text
	unit.description = description_source.text
	unit.image = image_source.texture
	
	unit.movement_type = movement_type_source.get_value() as int
	unit.movement_speed = movement_speed_source.get_value() as int
	
	unit.capturable = capturable_source.get_value() as int
	
	unit.health = health_source.get_value() as int
	unit.morale = morale_source.get_value() as int
	
	unit.damage = damage_source.get_value() as int
	unit.piercing = piercing_source.get_value() as int
	unit.accuracy = accuracy_source.get_value() as int
	unit.reach = reach_source.get_value() as int
	
	unit.armor = armor_source.get_value() as int
	unit.evasion = evasion_source.get_value() as int
	
	unit.perception = perception_source.get_value() as int
	unit.vision_range = vision_range_source.get_value() as int
	
	unit.victory_points = victory_points_source.get_value() as int
	
	ResourceSaver.save(unit, "user://units/{name}.tres".format({"name" : name_source.text}))
	
func _show_load_dialog() -> void:
	load_dialog.show()
	
func _load_unit(path : String) -> void:
	var data = ResourceLoader.load(path) as UnitResource
	name_source.text = data.name
	description_source.text = data.description
	image_source.texture = data.image
	
	
	
func _pick_image() -> void:
	image_picker.show()

func _set_image(path: String) -> void:
	var image = Image.load_from_file(path)
	image_source.texture = ImageTexture.create_from_image(image)
	
func _init() -> void:
	if not DirAccess.dir_exists_absolute("user://units"):
		DirAccess.make_dir_absolute("user://units")

func _ready() -> void:
	load_dialog.root_subfolder = "units"
