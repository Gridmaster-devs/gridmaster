extends PopupWindow
class_name GameOverPopup

@onready var _message_label: Label = $EditorPanel/TopVBox/TopLabel
@onready var _ok_button: Button = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/HBoxContainer/Ok


func _init() -> void:
	set_popup_name("game_over_popup")


func _ready() -> void:
	_ok_button.pressed.connect(_on_ok_pressed)
	center()


func show_result(message: String) -> void:
	add_to_tree()
	_message_label.text = message
	center()


func _on_ok_pressed() -> void:
	remove_from_tree()
