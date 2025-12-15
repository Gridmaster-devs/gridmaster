# the root unit editor class
class_name UnitEditor
extends PanelContainer

# these signals are sent to the various children of the unit editor
signal save_to_resource(resource : UnitResourceDict)
signal load_from_resource(resource : UnitResourceDict)
signal update_resources(resources : Array[String])
signal reset

# the current unit resource
# note that the full array of unit resources is held by the tree panel,
# not the unit editor
var unit_resource : UnitResourceDict

# list of resource attributes
var resources : Array[String] = []
@onready var tree_panel : FileTreePanel = $HBoxContainer/UnitTreePanel
@onready var info_panel : UnitInfoPanel = $HBoxContainer/VBoxContainer/UnitInfoPanel
@onready var save_dialog : FileDialog = $Dialogs/SaveUnitDialog
@onready var load_dialog : FileDialog = $Dialogs/LoadUnitDialog
@onready var action_panel : ActionPanel = $HBoxContainer/ActionPanel

# called when the user changes the name of the unit in the editor
func update_name_in_tree(new_name : String):
	if (unit_resource != null):
		tree_panel.update_selected_name(new_name)


# called when the user clicks the save button
func show_save_dialog():
	save_to_resource.emit(unit_resource)
	save_dialog.show()
	

# called when the user clicks the load button
func show_load_dialog():
	load_dialog.show()


# called by the save dialog itself if a filepath is selected
func save_to_file(path : String):
	ResourceSaver.save(unit_resource, path)
	

# called by the load dialog itself if a filepath is selected
func load_from_file(path : String):
	if (ResourceLoader.exists(path)):
		var data : UnitResourceDict = ResourceLoader.load(path) as UnitResourceDict
		tree_panel.add_unit_from_resource(data)
		

# lets the UI elements know the current edited unit was removed, so they
# should reset their values
func unit_resource_removed():
	unit_resource = null
	reset.emit()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	action_panel.update_resource_array(resources)
	
	save_dialog.file_selected.connect(save_to_file)
	load_dialog.file_selected.connect(load_from_file)
	
	info_panel.get_save_button().button_up.connect(show_save_dialog)
	info_panel.get_load_button().button_up.connect(show_load_dialog)
	
	update_resources.emit(resources)
	
	action_panel.link_unit_editor(self)
	info_panel.link_unit_editor(self)
	tree_panel.link_unit_editor(self)
	
	
# called by the tree panel when the user selects a new unit from the list
# and the new unit's info should be displayed
func new_unit_resource(unit_resource_p : UnitResourceDict):
	save_to_resource.emit(unit_resource)
	load_from_resource.emit(unit_resource_p)
	unit_resource = unit_resource_p
	

func save_to_json():
	if unit_resource != null:
		var json = JSON.new()
		var str = JSON.stringify(unit_resource)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
