# base class for action resources
# each action should be a subclass of this one
class_name Action
extends Resource

# when you make a new subclass, make sure to add it here
enum Type {NONE = -1, CONSUMEPRODUCE = 0}

@export var action_name : String
@export var action_type : Type
