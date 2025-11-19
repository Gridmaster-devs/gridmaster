extends Control

@export var unit_stats : Resource
@export var unit_name : LineEdit
@export var unit_description : TextEdit

func _save_unit() -> void:
	var unit = UnitStats.new()
	unit.description = unit_description.text
	unit.name = unit_name.text
	ResourceSaver.save(unit, "user://units/{name}.tres".format({"name" : unit_name.text}))
	print("Saved unit {name}".format({"name" : unit_name.text}))
