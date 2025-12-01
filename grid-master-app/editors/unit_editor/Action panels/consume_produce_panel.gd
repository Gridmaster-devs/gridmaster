class_name ConsumeProducePanel
extends VBoxContainer

var resources : Array[String]
@onready var consumes_amount : SpinBox = $Consumes/ResourceAmount
@onready var consumes_name : OptionButton = $Consumes/ResourceName
@onready var produces_amount : SpinBox = $Produces/ResourceAmount
@onready var produces_name : OptionButton = $Produces/ResourceName

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	


func _init(editor_resources : Array[String]) -> void:
	resources = editor_resources
	for item in editor_resources:
		consumes_name.add_item(item, -1)
		produces_name.add_item(item, -1)
	
