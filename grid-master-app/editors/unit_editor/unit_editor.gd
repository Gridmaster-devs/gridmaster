class_name UnitEditor
extends PanelContainer

signal save_to_resource(resource : UnitResourceDict)
signal load_from_resource(resource : UnitResourceDict)
signal reset

var unit_resource : UnitResourceDict
@onready var tree_panel : FileTreePanel = $HBoxContainer/UnitTreePanel
@onready var info_panel : UnitInfoPanel = $HBoxContainer/VBoxContainer/UnitInfoPanel
@onready var save_dialog : FileDialog = $Dialogs/SaveUnitDialog
@onready var load_dialog : FileDialog = $Dialogs/LoadUnitDialog

func update_name_in_tree(new_name : String):
	if (unit_resource != null):
		tree_panel.update_selected_name(new_name)

func show_save_dialog():
	save_to_resource.emit(unit_resource)
	save_dialog.show()
	
func show_load_dialog():
	load_dialog.show()

func save_to_file(path : String):
	ResourceSaver.save(unit_resource, path)
	
func load_from_file(path : String):
	if (ResourceLoader.exists(path)):
		var data : UnitResourceDict = ResourceLoader.load(path) as UnitResourceDict
		tree_panel.add_unit_from_resource(data)
		

func unit_resource_removed():
	unit_resource = null
	reset.emit()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	save_dialog.file_selected.connect(save_to_file)
	load_dialog.file_selected.connect(load_from_file)
	info_panel.get_save_button().button_up.connect(show_save_dialog)
	info_panel.get_load_button().button_up.connect(show_load_dialog)
	
	

func new_unit_resource(unit_resource_p : UnitResourceDict):
	save_to_resource.emit(unit_resource)
	load_from_resource.emit(unit_resource_p)
	unit_resource = unit_resource_p

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
func test():
	print("test successful")
