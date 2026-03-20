class_name MapResource
extends Resource

@export var _strategic_map: MapPainterRes
@export var _tactical_maps: Dictionary[String, MapPainterRes]


func init(strategic_map: MapPainterRes, tactical_maps: Dictionary[String, MapPainterRes]) -> void: 
	_strategic_map = strategic_map
	_tactical_maps = tactical_maps

func get_strategic_map() -> MapPainterRes:
	return _strategic_map.duplicate(true)

func get_tactical_maps() -> Dictionary[String, MapPainterRes]:
	return _tactical_maps.duplicate(true)
