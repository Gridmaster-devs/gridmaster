# child of an action panel item
# edits a MoveCost: which resource moving the unit costs, how much, and whether it is consumed
class_name MoveCostPanel
extends Control

const MODE_TEXTS : Dictionary[MoveCost.Mode, String] = {
	MoveCost.Mode.CONSUME: "Consume",
	MoveCost.Mode.REQUIRE: "Require only",
}

var resources : Array[String]
var _charge : MoveCost.Charge = MoveCost.Charge.PER_ORDER
@onready var resource_box : OptionButton = $Cost/ResourceName
@onready var resource_amount : SpinBox = $Cost/ResourceAmount
@onready var mode_box : OptionButton = $Mode/ModeOption
@onready var none_warning : Label = $NoneWarning


func _ready() -> void:
	resource_box.item_selected.connect(_update_none_warning)
	resource_amount.value_changed.connect(_update_none_warning)


# EVERY TYPE OF ACTION SUBPANEL MUST HAVE THIS FUNCTION
func load_from_action(action : Action):
	if !(action is MoveCost):
		return
	var mc := action as MoveCost

	# Unlike consume / produce, a name the game doesn't define is kept and shown as it is,
	# so the designer sees it. Moving with an undefined resource is refused in the game.
	# An empty name means no cost, the same as None.
	var cost_resource : String = mc.cost_resource if mc.cost_resource != "" else ConsumeProduce.NO_RESOURCE
	if !HelperFuncs.select_with_text(resource_box, cost_resource):
		resource_box.add_item(cost_resource, -1)
		HelperFuncs.select_with_text(resource_box, cost_resource)

	resource_amount.value = mc.amount
	mode_box.select(mode_box.get_item_index(mc.mode))
	_charge = mc.charge
	_update_none_warning()


# Warns that an amount was set but no resource was picked, which makes moving free
func _update_none_warning(_changed = null) -> void:
	none_warning.visible = resource_amount.value > 0 and HelperFuncs.get_text_selected(resource_box) == ConsumeProduce.NO_RESOURCE


# EVERY TYPE OF ACTION SUBPANEL MUST HAVE THIS FUNCTION
func save_to_action() -> MoveCost:
	var mc := MoveCost.new()
	resource_amount.apply()
	mc.cost_resource = HelperFuncs.get_text_selected(resource_box)
	mc.amount = int(resource_amount.value)
	mc.mode = mode_box.get_selected_id() as MoveCost.Mode
	mc.charge = _charge
	mc.action_type = Action.Type.MOVECOST
	return mc


# just adds the resources and modes to the dropdown menus
func initiate(editor_resources : Array[String]) -> void:
	resources = editor_resources
	resource_box.add_item(ConsumeProduce.NO_RESOURCE, -1)
	for item in editor_resources:
		resource_box.add_item(item, -1)
	for mode in MODE_TEXTS:
		mode_box.add_item(MODE_TEXTS[mode], mode)
