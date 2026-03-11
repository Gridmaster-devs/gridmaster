extends Node
class_name TeamUi


@onready var _color_button: Button = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/HBoxContainer/ColorButton
@onready var _team_color_rect: TextureRect = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/HBoxContainer/TeamColor
@onready var _team_name_ui: LineEdit = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Name/TeamName
var _color: Color


func _ready() -> void:
	_color_button.pressed.connect(_open_color_picker)


func _open_color_picker() -> void:
	var color_picker_popup: TextureColorPicker = preload("res://editor/editors/map_editor_refactor/popup_windows/color_picker.tscn").instantiate()
	get_tree().call_group(Global.popup_manager_group, Global.add_popup, color_picker_popup, color_picker_popup.get_popup_name())
	color_picker_popup.color_saved.connect(_on_color_picker_color)
	color_picker_popup.texture_saved.connect(_on_color_picker_texture)

func _on_color_picker_color(color: Color) -> void: 
	_color = color
	
func _on_color_picker_texture(tex: Texture2D) -> void:
	_team_color_rect.texture = tex

func get_team_color() -> Color:
	return _color

func get_team_name() -> String: 
	return _team_name_ui.text
