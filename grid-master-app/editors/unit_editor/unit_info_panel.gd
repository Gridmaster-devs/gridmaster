class_name UnitInfoPanel
extends PanelContainer

var unit_editor : UnitEditor
@onready var save_button = $TopVBox/PanelContainer/ContentsVBox/HBoxContainer/VBoxContainer/Buttons/SaveButton
@onready var load_button = $TopVBox/PanelContainer/ContentsVBox/HBoxContainer/VBoxContainer/Buttons/LoadButton
@onready var name_line : LineEdit = $TopVBox/PanelContainer/ContentsVBox/NameLine
@onready var description_box = $TopVBox/PanelContainer/ContentsVBox/HBoxContainer/ScrollContainer/Description


func unit_name_changed(new_text : String):
	unit_editor.update_name_in_tree(new_text)
	

func save_to_resource(unit_resource : UnitResourceDict):
	if (unit_resource != null):
		var unit_name = name_line.text
		if (unit_name == ""):
			unit_resource.set_attribute("name", "")
		else:
			unit_resource.set_attribute("name", unit_name)
			
		var unit_description = description_box.text
		unit_resource.set_attribute("description", unit_description)


func load_from_resource(unit_resource : UnitResourceDict):
	if (unit_resource != null):

		var unit_name = unit_resource.get_attribute_value("name")
		if (unit_name == "" or unit_name == null):
			name_line.text = ""
		else:
			name_line.text = unit_name
			
		var unit_description = unit_resource.get_attribute_value("description")
		if (unit_description == null):
			description_box.text = ""
		else:
			description_box.text = unit_description
			
func get_save_button() -> Button:
	return save_button
	
	
func get_load_button() -> Button:
	return load_button
	
	
func reset():
	name_line.text = ""
	description_box.text = ""
	
	
func link_unit_editor(ue : UnitEditor):
	unit_editor = ue
	unit_editor.save_to_resource.connect(save_to_resource)
	unit_editor.load_from_resource.connect(load_from_resource)
	unit_editor.reset.connect(reset)
	name_line.text_changed.connect(unit_name_changed)
		
		
func _ready():
	pass
