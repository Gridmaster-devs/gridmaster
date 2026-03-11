extends PopupWindow
class_name ConfirmPopup

@onready var _ok_button: Button = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/HBoxContainer/Ok
@onready var _cancel_button: Button = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox/HBoxContainer/Cancel


#signals
signal ok


func _init() -> void:
	set_popup_name("ok_popup")

func _ready() -> void:
	_ok_button.pressed.connect(_ok)
	_cancel_button.pressed.connect(_cancel)
	
func _ok() -> void:
	ok.emit()
	
func _cancel() -> void:
	remove_from_tree()
