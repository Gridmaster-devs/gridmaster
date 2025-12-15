class_name GameEditor
extends Control

var editor_main : EditorMain
var game_resource : GameDefinitionResource
@onready var game_name_line : LineEdit = $"PanelContainer/VBoxContainer/Game name"
@onready var save_game_button : Button = $"PanelContainer/VBoxContainer/Save game"
@onready var load_game_button : Button = $"PanelContainer/VBoxContainer/Load game"
@onready var save_dialog : FileDialog = $Dialogs/SaveUnitDialog
@onready var load_dialog : FileDialog = $Dialogs/LoadUnitDialog

func link_editor_main(editor_main_p : EditorMain):
	editor_main = editor_main_p

func save_to_resource():
	var units = editor_main.get_units()
	
	game_resource = GameDefinitionResource.new()
	game_resource.save_name(get_game_name())
	game_resource.save_units(units)
	
	# TODO: Get map data
	save_dialog.show()
	
	
func show_load_dialog():
	load_dialog.show()


func load_from_resource(resource : GameDefinitionResource):
	set_game_name(resource.game_name)
	editor_main.set_units(resource.load_units())
	
	
func get_game_name() -> String:
	return game_name_line.text
	
	
func set_game_name(name_p : String):
	game_name_line.text = name_p
	
	
func save_to_file(path : String):
	ResourceSaver.save(game_resource, path)


func load_from_file(path : String):
	var data : GameDefinitionResource = ResourceLoader.load(path) as GameDefinitionResource
	if data != null:
		load_from_resource(data)
	


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	save_dialog.file_selected.connect(save_to_file)
	load_dialog.file_selected.connect(load_from_file)
	save_game_button.button_up.connect(save_to_resource)
	load_game_button.button_up.connect(show_load_dialog)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
