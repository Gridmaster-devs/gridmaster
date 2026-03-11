extends Control
class_name PopupManager

var _popups: Dictionary[String, Node]
var _containers: Dictionary[String, Container]

func _ready() -> void:
	self.visible = false

func add_popup(node: Node, popup_name: String) -> void: 
	var new_cont: Container = preload("res://editor/editors/map_editor_refactor/popup_windows/popup_layer.tscn").instantiate()
	add_child(new_cont)
	add_child(node)
	_popups[popup_name] = node
	_containers[popup_name] = new_cont
	self.visible = true


func close_popup(popup_name: String) -> void: 
	_popups[popup_name].queue_free()
	_containers[popup_name].queue_free()
	_popups.erase(popup_name)
	_containers.erase(popup_name)
	if _popups.is_empty(): 
		self.visible = false














##
