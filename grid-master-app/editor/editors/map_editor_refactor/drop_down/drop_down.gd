extends PopupWindow
class_name DropDown

@onready var _content = $EditorPanel/TopVBox/ScrollContainer/ContentsVBox

func _ready() -> void:
	position = get_global_mouse_position()


func add_button(callback: Callable, text: String) -> void: 
	var new_button = Button.new()
	new_button.text = text
	new_button.pressed.connect(callback)
	_content.add_child(new_button)

func _init() -> void:
	set_popup_name("dropdown")
