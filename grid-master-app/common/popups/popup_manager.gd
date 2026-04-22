extends Control
class_name PopupManager

var _popups: Dictionary[String, Node]
var _containers: Dictionary[String, Container]

func _ready() -> void:
	self.visible = false
	Global.popup_manager = self

func add_popup(popup: PopupWindow) -> void: 
	var new_cont: Container = preload("res://editor/editors/map_editor_refactor/popup_windows/popup_layer.tscn").instantiate()
	var popup_name: String = popup.get_popup_name()
	add_child(new_cont)
	add_child(popup)
	_popups[popup_name] = popup
	_containers[popup_name] = new_cont
	self.visible = true
	self.mouse_filter = Control.MOUSE_FILTER_STOP

func add_popup_non_blocking(popup: PopupWindow) -> void: 
	var popup_name: String = popup.get_popup_name()
	add_child(popup)
	_popups[popup_name] = popup
	self.visible = true
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE


func close_popup(popup: PopupWindow) -> void: 
	var popup_name = popup.get_popup_name()
	_popups[popup_name].queue_free()
	if _containers.has(popup_name):
		_containers[popup_name].queue_free()
		_containers.erase(popup_name)
	_popups.erase(popup_name)
	if _popups.is_empty(): 
		self.visible = false














##
