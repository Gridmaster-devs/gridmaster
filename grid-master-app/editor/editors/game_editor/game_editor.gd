class_name GameEditor
extends Control

var editor_main : EditorMain
var game_resource : GameDefinitionResource
@onready var game_name_line : LineEdit = $"PanelContainer/VBoxContainer/Game name"
@onready var save_game_button : Button = $"PanelContainer/VBoxContainer/Save game"
@onready var load_game_button : Button = $"PanelContainer/VBoxContainer/Load game"
@onready var ftm : FileTransferManager = $Dialogs/FileTransferManager


# links the editor_main object
func link_editor_main(editor_main_p : EditorMain):
	editor_main = editor_main_p


# called by pressing the save button
func save_to_file():
	var units = editor_main.get_units()
	var map = editor_main.getMap()
	
	game_resource = GameDefinitionResource.new()
	game_resource.save_name(get_game_name())
	game_resource.save_units(units)
	game_resource.saveMap(map)
	
	ftm.download_data(game_resource, "game_resource.tres", "*.tres", true)


func load_from_file() -> void:
	ftm.upload_data("*.tres", true)

# called by load_from_file
func load_from_resource(resource : GameDefinitionResource):
	set_game_name(resource.game_name)
	editor_main.set_units(resource.load_units())
	editor_main.setMap(resource.loadMap())


func get_game_name() -> String:
	return game_name_line.text
	
	
func set_game_name(name_p : String):
	game_name_line.text = name_p
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ftm.resource_uploaded.connect(load_from_resource)
	
	save_game_button.button_up.connect(save_to_file)
	load_game_button.button_up.connect(load_from_file)
