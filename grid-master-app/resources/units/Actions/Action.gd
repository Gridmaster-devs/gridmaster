# base class for action resources
class_name Action
extends Resource

enum Type {NONE = -1, CONSUMEPRODUCE = 0}

@export var action_name : String
@export var action_type : Type
