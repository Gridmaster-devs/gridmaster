# base class for action resources
class_name Action
extends Resource

enum Type {CONSUMEPRODUCE}

@export var action_name : String
@export var action_type : Type
