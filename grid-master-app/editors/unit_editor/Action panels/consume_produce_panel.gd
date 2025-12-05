class_name ConsumeProducePanel
extends Control

var resources : Array[String]
@onready var consumes_amount : SpinBox = $Consumes/ResourceAmount
@onready var consumes_name : OptionButton = $Consumes/ResourceName
@onready var produces_amount : SpinBox = $Produces/ResourceAmount
@onready var produces_name : OptionButton = $Produces/ResourceName


# EVERY TYPE OF ACTION SUBPANEL MUST HAVE THIS FUNCTION
# I'd enforce this with abstract classes, but the godot editor doesn't seem to work with them
func load_from_action(action : Action):
	
	if !(action is ConsumeProduce) or (action == null):
		return
		
	var cp = action as ConsumeProduce
	
	if (cp.consumed_resource != null):
		HelperFuncs.select_with_text(consumes_name, cp.consumed_resource)
		
	if (cp.produced_resource != null):
		HelperFuncs.select_with_text(produces_name, cp.produced_resource)
		
	if (cp.consumed_amount != null):
		consumes_amount.value = cp.consumed_amount
		
	if (cp.produced_amount != null):
		produces_amount.value = cp.produced_amount
		

# EVERY TYPE OF ACTION SUBPANEL MUST HAVE THIS FUNCTION
# I'd enforce this with abstract classes, but the godot editor doesn't seem to work with them
func save_to_action() -> ConsumeProduce:
	var cp = ConsumeProduce.new()
	
	consumes_amount.apply()
	produces_amount.apply()
	
	if (consumes_amount.value != null):
		cp.consumed_amount = consumes_amount.value
		
	if (produces_amount.value != null):
		cp.produced_amount = produces_amount.value
		
	if (consumes_name != null):
		cp.consumed_resource = HelperFuncs.get_text_selected(consumes_name)
		
	if (produces_name != null):
		cp.produced_resource = HelperFuncs.get_text_selected(produces_name)
		
	cp.action_type = Action.Type.CONSUMEPRODUCE
		
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
	
