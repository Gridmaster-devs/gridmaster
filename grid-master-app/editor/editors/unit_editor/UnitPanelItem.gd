@tool
class_name UnitPanelItem
extends PanelItem

# this is the name of the attribute that will be saved in the dictionary
@export var attribute_name : String

# the resource flag determines whether the attribute counts as a resource, and thus
# whether it shows up in places for resources, like certain actions
@export_flags ("Resource") var flags : int = 0
var root_editor : UnitEditor

func save_to_unit_resource(resource_p : UnitResourceDict):
	if (resource_p != null):
		resource_p.set_attribute(attribute_name, get_value())
	
func load_from_unit_resource(resource_p : UnitResourceDict):
	if (resource_p != null):
		var value = resource_p.get_attribute_value(attribute_name)
		if (value != null):
			# this assumes that the type of the attribute is the same in the dictionary and in here
			# this obviously means that if the value type of an attribute changes between versions their units
			# won't be compatible with each other
			set_value(value) 
			return

	reset()
		

func _on_save_to_resource(resource : UnitResourceDict):
	save_to_unit_resource(resource)
	
func _on_load_from_resource(resource : UnitResourceDict):
	load_from_unit_resource(resource)
	
# super super jank but I don't know a better way right now
# some way to do globals would probably be the best way
func find_root_unit_editor():
	var cur_node = self.get_parent()
	while true:
		if cur_node is UnitEditor:
			root_editor = cur_node
		elif cur_node == null:
			break
		cur_node = cur_node.get_parent()


# checks whether the resource flag is on
func resource_flag() -> bool:
	if ((flags & 1) > 0):
		return true
	else:
		return false

# adds itself to the resources if the resource flag is set
func update_resources(resources : Array[String]):
	if (resource_flag()):
		resources.append(attribute_name)
	
func _ready():
	if !Engine.is_editor_hint():
		find_root_unit_editor()
		if root_editor != null:
			root_editor.save_to_resource.connect(save_to_unit_resource)
			root_editor.load_from_resource.connect(load_from_unit_resource)
			root_editor.update_resources.connect(update_resources)
			self.add_to_group("value_fields")
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE
