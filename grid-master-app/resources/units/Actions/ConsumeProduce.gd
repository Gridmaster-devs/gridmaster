class_name ConsumeProduce
extends Action

@export var consumed_resource : String
@export var consumed_amount : int
@export var produced_resource : String
@export var produced_amount : int

func set_consumed(consumed_name : String, amount : int) -> void:
	if (consumed_name != null and consumed_name != "" and amount >= 0):
		consumed_resource = consumed_name
		consumed_amount = amount
		
func set_produced(produced_name : String, amount : int) -> void:
	if (produced_name != null and produced_name != "" and amount >= 0):
		produced_resource = produced_name
		produced_amount = amount

func get_consumed_name() -> String:
	return consumed_resource
	
func get_produced_name() -> String:
	return produced_resource

func get_consumed_amount() -> int:
	return consumed_amount
	
func get_produced_amount() -> int:
	return produced_amount
