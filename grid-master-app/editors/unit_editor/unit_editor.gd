class_name UnitEditor
extends PanelContainer

signal save_to_resource(resource : UnitResourceDict)
signal load_from_resource(resource : UnitResourceDict)

var unit_resource : UnitResourceDict

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	unit_resource = UnitResourceDict.new()
	test()
	save_to_resource.emit(unit_resource)
	unit_resource.print_all()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
func test():
	print("test successful")
