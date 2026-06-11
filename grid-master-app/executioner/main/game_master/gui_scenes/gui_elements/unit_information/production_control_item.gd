extends Control
class_name ProductionControlItem

signal production_selected

@onready var _selector: OptionButton = $VBoxContainer/OptionButton
@onready var _button: Button = $VBoxContainer/Button

var _unit: Unit
var _producible_unit: UnitType
var _unit_options: Array[UnitType]
var _game_data_manager: GameDataManager

# Setups the optionbutton and the produce
func setup(unit: Unit, game_data_manager: GameDataManager):
	_selector.clear()
	_unit = unit
	_unit_options = _unit.type.producible_units
	_game_data_manager = game_data_manager
	
	for u in _unit_options:
		_selector.add_item(u.unit_name)
	
	_button.text = "Produce"

func _on_pressed() -> void:
	var selected = _selector.get_item_text(_selector.selected)
	
	for u in _unit_options:
		if u.unit_name == selected:
			_producible_unit = u
	
	if _unit.current_action == null:
		_unit.current_action = ProductionAction.new(_unit.get_player_id(), _unit, _game_data_manager, _producible_unit)
		production_selected.emit()
	
func _ready() -> void:
	_button.pressed.connect(_on_pressed)
