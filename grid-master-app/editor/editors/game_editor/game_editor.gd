class_name GameEditor
extends Control

var editor_main : EditorMain
var game_resource : GameDefinitionResource
@onready var game_name_line : LineEdit = $"PanelContainer/VBoxContainer/Game name"
@onready var save_game_button : Button = $"PanelContainer/VBoxContainer/Save game"
@onready var load_game_button : Button = $"PanelContainer/VBoxContainer/Load game"
@onready var save_dialog : FileDialog = $Dialogs/SaveUnitDialog
@onready var load_dialog : FileDialog = $Dialogs/LoadUnitDialog


# links the editor_main object
func link_editor_main(editor_main_p : EditorMain):
	editor_main = editor_main_p


# called by pressing the save button
func save_to_resource():
	var units = editor_main.get_units()
	var map = editor_main.getMap()
	
	game_resource = GameDefinitionResource.new()
	game_resource.save_name(get_game_name())
	game_resource.save_units(units)
	game_resource.saveMap(map)
	
	save_dialog.show()


# called by the load button
func show_load_dialog():
	load_dialog.show()


# called by load_from_file
func load_from_resource(resource : GameDefinitionResource):
	set_game_name(resource.game_name)
	editor_main.set_units(resource.load_units())
	editor_main.setMap(resource.loadMap())


# called by the save dialog when a file is selected
func save_to_file(path : String):
	ResourceSaver.save(game_resource, path)


# called by the load dialog when a file is selected
func load_from_file(path : String):
	var data : GameDefinitionResource = ResourceLoader.load(path) as GameDefinitionResource
	if data != null:
		load_from_resource(data)
	
func get_game_name() -> String:
	return game_name_line.text
	
	
func set_game_name(name_p : String):
	game_name_line.text = name_p
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	save_dialog.file_selected.connect(save_to_file)
	load_dialog.file_selected.connect(load_from_file)
	save_game_button.button_up.connect(save_to_resource)
	load_game_button.button_up.connect(show_load_dialog)
