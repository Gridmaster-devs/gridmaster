class_name SaveNamePopup
extends PopupWindow

@onready var _save_button: Button = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/SaveButton
@onready var _tact_map_name_ui: LineEdit = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/HBoxContainer/LineEdit


signal save_confirmed(name: String)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_save_button.pressed.connect(_on_save)
	center()


func _init() -> void:
	set_popup_name("save_name_popup")


func _on_save() -> void: 
	save_confirmed.emit(_tact_map_name_ui.text)
	remove_from_tree()
