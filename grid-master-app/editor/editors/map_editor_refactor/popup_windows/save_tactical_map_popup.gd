class_name SaveTacticalMapPopup
extends PopupWindow

@onready var _save_button: Button = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/SaveButton
@onready var _tact_map_name_ui: LineEdit = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/HBoxContainer/LineEdit


signal tactical_map_saved(name: String)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_save_button.pressed.connect(_on_save)


func _init() -> void:
	set_popup_name("save_tactical_map_popup")


func _on_save() -> void: 
	tactical_map_saved.emit(_tact_map_name_ui.text)
