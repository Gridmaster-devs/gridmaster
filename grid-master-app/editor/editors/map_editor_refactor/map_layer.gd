class_name MapLayer



var _attribute_grid: Array2D = Array2D.new()
var _tile_map_layer: TileMapLayer = TileMapLayer.new()


func resize(width: int, height: int) -> void:
	pass




func get_tile_map_layer() -> TileMapLayer: 
	return _tile_map_layer




func get_attribute_grid() -> Array2D:
	return _attribute_grid
