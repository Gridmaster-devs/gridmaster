# the root unit editor class
class_name UnitEditor
extends PanelContainer

# these signals are sent to the various children of the unit editor
signal save_to_resource(resource : UnitResource)
signal load_from_resource(resource : UnitResource)
signal update_resources(resources : Array[String])

# the current unit resource
# note that the full array of unit resources is held by the tree panel,
# not the unit editor
var unit_resource : UnitResource

# list of resource attributes
var resources : Array[String] = []
var editor_main : EditorMain
@onready var tree_panel : FileTreePanel = $HBoxContainer/UnitTreePanel
@onready var info_panel : UnitInfoPanel = $HBoxContainer/VBoxContainer/UnitInfoPanel
@onready var action_panel : ActionPanel = $HBoxContainer/ActionPanel
@onready var ftm : FileTransferManager = $Dialogs/FileTransferManager

@onready var production_options: PanelItemEditableList = $"HBoxContainer/VBoxContainer/HBoxContainer/AttributesPanel/TopVBox/ScrollContainer/ContentsVBox/Production/Producible units"
@onready var producible_item: UnitPanelItem = $"HBoxContainer/VBoxContainer/HBoxContainer/AttributesPanel/TopVBox/ScrollContainer/ContentsVBox/Production/Is producible unit"
@onready var production_item: UnitPanelItem = $"HBoxContainer/VBoxContainer/HBoxContainer/AttributesPanel/TopVBox/ScrollContainer/ContentsVBox/Production/Production unit"


# called when the user changes the name of the unit in the editor


func update_name_in_tree(new_name : String):
	if (unit_resource != null):
		tree_panel.update_selected_name(new_name)

## Saves a unit to file
##
## Called when the user clicks the save button


func save_to_file():
	if (unit_resource == null): return
	save_to_resource.emit(unit_resource)
	var file_name = unit_resource.get_attribute("name").get_attribute_value() + ".tres"
	ftm.download_data(unit_resource, file_name, "*.tres", true)
	
## Loads a unit from file.
##
## Called when the user clicks the load button.


func load_from_file():
	ftm.upload_data("*.tres", true) 


## Loads a resource


func load_resource(resource : Resource):
	tree_panel.add_unit_from_resource(resource)

	

## Loads in a new set of units from an array to replace current ones.
##
## Called by the editor main when loading in a game definition


func set_units(units_p : Array[UnitResource]) -> bool:
	return tree_panel.set_units(units_p)
		
		


func get_units() -> Array[UnitResource]:
	if (unit_resource != null):
		save_to_resource.emit(unit_resource)
	return tree_panel.get_units()

# TODO just use signals or something
# lets the UI elements know the current edited unit was removed, so they
# should reset their values


func unit_resource_removed() -> void:
	unit_resource = null
	production_options.hide()
	production_options._reset_chosen()
	get_tree().call_group("panel_items", "reset")
	get_tree().call_group("info_panel", "reset")
	get_tree().call_group("action_panel_items", "self_destruct")

# called by the tree panel when the user selects a new unit from the list
# and the new unit's info should be displayed


func new_unit_resource(unit_resource_p : UnitResource) -> void:
	save_to_resource.emit(unit_resource)
	load_from_resource.emit(unit_resource_p)
	unit_resource = unit_resource_p
	_update_production_options_visibility(production_item.get_value())

## Remove references to known ineligible units, retaining IDs not imported yet.


func _on_units_changed() -> void:
	var units: Array[UnitResource] = tree_panel.get_units()
	var disabled_ids: Array[int] = []
	for unit in units:
		if unit.get_attribute_value("is_producible_unit") != true:
			disabled_ids.append(unit.id)
	for unit in units:
		var saved_ids: Variant = unit.get_attribute_value("producible_units")
		if saved_ids is Array:
			var eligible_ids: Array = saved_ids.filter(func(id: Variant) -> bool: return id not in disabled_ids)
			if eligible_ids.size() != saved_ids.size():
				unit.set_attribute("producible_units", eligible_ids)
	production_options.options_changed()


func _update_production_options_visibility(enabled: bool) -> void:
	production_options.visible = unit_resource != null and enabled


func _on_producible_toggled(_enabled: bool) -> void:
	if unit_resource == null:
		return
	producible_item.save_to_unit_resource(unit_resource)
	tree_panel.units_changed.emit()


func link_editor_main(editor_main_p : EditorMain):
	editor_main = editor_main_p

# Called when the node enters the scene tree for the first time.


func _ready() -> void:
	
	action_panel.update_resource_array(resources)
	
	info_panel.get_save_button().button_up.connect(save_to_file)
	info_panel.get_load_button().button_up.connect(load_from_file)
	
	ftm.resource_uploaded.connect(load_resource)
	
	update_resources.emit(resources)
	
	action_panel.link_unit_editor(self)
	info_panel.link_unit_editor(self)
	tree_panel.link_unit_editor(self)
	
	# TODO move other signal connections here as well, signals should be connected by parents not in the child itself (do away with all of
	# these "child.link(parent)" calls like above that enforce tight coupling)
	
	tree_panel.units_changed.connect(_on_units_changed)
	producible_item.get_content().toggled.connect(_on_producible_toggled)
	production_item.get_content().toggled.connect(_update_production_options_visibility)
	save_to_resource.connect(production_options._save_to_unit_resource)
	load_from_resource.connect(production_options._load_from_unit_resource)
