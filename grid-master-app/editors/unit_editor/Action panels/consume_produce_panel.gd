class_name ConsumeProducePanel
extends VBoxContainer

var resources : Array[String]
@onready var consumes_amount : SpinBox = $Consumes/ResourceAmount
@onready var consumes_name : OptionButton = $Consumes/ResourceName
@onready var produces_amount : SpinBox = $Produces/ResourceAmount
@onready var produces_name : OptionButton = $Produces/ResourceName


func load_from_action(action : Action):
	
	if !(action is ConsumeProduce) or (action == null):
		return
		
	var cp = action as ConsumeProduce
	
	if (cp.consumed_resource != null):
		consumes_name.select_with_text(cp.consumed_resource)
		
	if (cp.produced_resource != null):
		produces_name.select_with_text(cp.produced_resource)
		
	if (cp.consumed_amount != null):
		consumes_amount = cp.consumed_amount
		
	if (cp.produced_amount != null):
		produces_amount = cp.produced_amount
		

func save_to_action() -> ConsumeProduce:
	var cp = ConsumeProduce.new()
	
	if (consumes_amount.value != null):
		cp.consumed_amount = consumes_amount
		
	if (produces_amount.value != null):
		cp.produced_amount = produces_amount
		
	if (consumes_name != null):
		cp.consumed_resource = consumes_name
		
	if (produces_name != null):
		cp.produced_resource = produces_name
	
	return cp
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	

func initiate(editor_resources : Array[String]) -> void:
	resources = editor_resources
	for item in editor_resources:
		consumes_name.add_item(item, -1)
		produces_name.add_item(item, -1)

func _init():
	pass
	
