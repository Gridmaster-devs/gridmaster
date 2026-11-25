extends Control
class_name ProductionControlItem

signal production_selected

@onready var _selector: OptionButton = $VBoxContainer/OptionButton
@onready var _button: Button = $VBoxContainer/Button

var _unit: Unit
var _game_data_manager: GameDataManager

# Setups the optionbutton and the produce
func setup(unitID: int, game_data_manager: GameDataManager):
	_selector.clear()
	_unit = game_data_manager.get_unit_by_id(unitID)
	_game_data_manager = game_data_manager
	
	for u in _unit.type.producible_units:
		_selector.add_item(u.unit_name)
	
	_button.text = "Produce"
	_button.disabled = not _unit.type.is_production_unit or _unit.type.producible_units.is_empty()

func _on_pressed() -> void:
	if _unit == null or not _unit.type.is_production_unit or _unit.current_action != null:
		return
	var selected := _selector.selected
	if selected < 0 or selected >= _unit.type.producible_units.size():
		return
	var target := _unit.type.producible_units[selected]
	_unit.current_action = ProductionAction.new(_unit.get_player_id(), _unit, _game_data_manager, target)
	production_selected.emit()
	
func _ready() -> void:
	_button.pressed.connect(_on_pressed)
