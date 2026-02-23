class_name MapPainterPopupManager
extends PopupManager



func _init() -> void:
	super("map_painter_popup_manager")

func new_tile_confirmed(data: Dictionary[String, Variant], lib_name: String) -> void: 
	if _parent.is_active() and _parent is MapPainter:
		_parent.add_new_lib_item(data, lib_name)

func settings_confirmed(settings: Dictionary[String, Variant]) -> void:
	if _parent.is_active() and _parent is MapPainter:
		_parent.update_settings(settings)

















##
