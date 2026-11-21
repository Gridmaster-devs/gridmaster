class_name ResourceEntry
extends PanelContainer
## One global resource in the in-game resource bar: its icon, amount and name

var _resource_name: String
var _amount: int
var _icon: Texture2D

@onready var _icon_rect: TextureRect = $HBoxContainer/Icon
@onready var _icon_fallback: PanelContainer = $HBoxContainer/IconFallback
@onready var _initial_label: Label = $HBoxContainer/IconFallback/InitialLabel
@onready var _amount_label: Label = $HBoxContainer/TextVBox/AmountLabel
@onready var _name_label: Label = $HBoxContainer/TextVBox/NameLabel

## Call before adding the entry to the tree.
## Without an icon, the first letter of the resource's name is shown in its place.
func init_params(resource_name: String, amount: int, icon: Texture2D) -> void:
	_resource_name = resource_name
	_amount = amount
	_icon = icon

func _ready():
	_icon_rect.texture = _icon
	_icon_rect.visible = _icon != null
	_icon_fallback.visible = _icon == null
	_initial_label.text = _resource_name.left(1).to_upper()
	_amount_label.text = str(_amount)
	_name_label.text = _resource_name.to_upper()
	tooltip_text = "%s: %d" % [_resource_name, _amount]
