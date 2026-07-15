class_name ProductionProgressItem
extends Control

var _progress: float
var _producing_unit: String

@onready var progress_bar = $ProgressBar
@onready var producing_unit_label = $"Producing Unit"

func init_params(progress: float, unit: String) -> void:
	_progress = progress
	_producing_unit = unit
	
func _ready():
	progress_bar.set_value_no_signal(_progress)
	producing_unit_label.text = "Producing: %s" % _producing_unit
