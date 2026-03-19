class_name MapLayer

var _attribute_grid: Array2D = Array2D.new()
var _tile_map_layer: TileMapLayer = TileMapLayer.new()
var _tile_texture_tileatlas_source_map: Dictionary[Texture2D, int]
var _tile_texture_id: Variant
var _tile_id: Variant
const _PAINT_TILE_ATLAS_CORD: Vector2i = Vector2i(0,0)



func _init(width: int, height: int, tile_texture_id: Variant, tile_id: Variant) -> void:
	_attribute_grid.init(width, height)
	_tile_id = tile_id
	_tile_texture_id = tile_texture_id
	#init the attribute_grid
	reset_attribute_grid(width, height)
	#tilemaplayer
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(Global.tile_width, Global.tile_height)
	_tile_map_layer.tile_set = tileset


func paint_tile(tile: Vector2i, tex: Texture2D) -> void: 
	if !_tile_texture_tileatlas_source_map.has(tex):
		add_new_atlas_source(tex)
	_tile_map_layer.set_cell(tile, _tile_texture_tileatlas_source_map[tex], _PAINT_TILE_ATLAS_CORD)
	
	
func overwrite_tile_attribute(tile: Vector2i, key: String, value: Variant) -> void:
	_attribute_grid.getItem(tile.x, tile.y)[key] = value

func add_tile_attribute(tile: Vector2i, key: String, value: Variant) -> void: 
	if !_attribute_grid.getItem(tile.x, tile.y).has(key):
		_attribute_grid.getItem(tile.x, tile.y)[key] = []
	if !(_attribute_grid.getItem(tile.x, tile.y)[key] is Array):
		print("trying to add to add to a non addable type with key: " + str(key))
		return
	_attribute_grid.getItem(tile.x, tile.y)[key].append(value)

#completely resets the grids, clears them and 
#doesnt preserve data (cmp to updateGrids()) 
func reset_grids(width: int, height: int) -> void: 
	reset_attribute_grid(width, height)
	update_tile_map()

#fully reloads the attribute grid and tilemaplayers based on new dimension
#preserves old data 
func update_grids(width: int, height: int) -> void: 
	update_attribute_grid(width, height)
	update_tile_map()

func get_tile_map_layer() -> TileMapLayer: 
	return _tile_map_layer

func get_attribute_grid() -> Array2D:
	return _attribute_grid

#totally clears the attribute grid and initializes it with new dimensions
func reset_attribute_grid(width: int, height: int) -> void: 
	_attribute_grid = _create_initialized_attribute_grid(width, height)

func update_attribute_grid(width: int, height: int) -> void:
	_attribute_grid = _create_resized_attribute_grid(width, height)


func _create_initialized_attribute_grid(width: int, height: int) -> Array2D: 
	var new_attribute_grid = Array2D.new()
	new_attribute_grid.init(width, height)
	for x in width: 
		for y in height: 
			var new_val: Dictionary[String, Variant] = {}
			new_attribute_grid.setItem(x, y, new_val)
	return new_attribute_grid

func _create_resized_attribute_grid(width: int, height: int) -> Array2D: 
	var new_attribute_grid = _create_initialized_attribute_grid(width, height)
	for x in min(_attribute_grid.width, width): 
		for y in min(_attribute_grid.height, height):
			if _attribute_grid.getItem(x, y) is Dictionary:
				new_attribute_grid.setItem(x, y, _attribute_grid.getItem(x, y))
	return new_attribute_grid


#updates tile map layer based on attribute grid
#clears and sets textures again
#will add new source ids if missign textures 
func update_tile_map() -> void: 
	_tile_map_layer.clear()
	for x in _attribute_grid.width: 
		for y in _attribute_grid.height: 
			if _attribute_grid.getItem(x, y).has(_tile_texture_id): 
				var tex = _attribute_grid.getItem(x, y)[_tile_texture_id]
				if !_tile_texture_tileatlas_source_map.has(tex):
					add_new_atlas_source(tex)
				_tile_map_layer.set_cell(Vector2i(x, y), _tile_texture_tileatlas_source_map[tex], _PAINT_TILE_ATLAS_CORD)

func add_new_atlas_source(tex: Texture2D) -> void:
	var tile_set = _tile_map_layer.tile_set
	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(Global.tile_width, Global.tile_height)
	source.create_tile(Vector2i(0,0))
	_tile_texture_tileatlas_source_map[tex] = tile_set.add_source(source)

#copies another attribute_grid, preserves "exclude" and doesnt overwrite them
func sync_attribute_grid(data: Array2D, exclude: Array[String]) -> void: 
	#copy the "exclude" key value pairs from _attribute_grid to new_grid
	var new_grid = data.duplicate_deep()
	for x in min(_attribute_grid.width, new_grid.width):
		for y in min(_attribute_grid.height, new_grid.height):
			if new_grid.getItem(x, y) is not Dictionary:
				var empty_dict: Dictionary[String, Variant] = {}
				new_grid.setItem(x, y, empty_dict)
			var tile = _attribute_grid.getItem(x, y)
			var new_tile = new_grid.getItem(x, y)
			for key in exclude: 
				if tile.has(key):
					new_tile[key] = tile[key]
	_attribute_grid = new_grid
	update_grids(_attribute_grid.width, _attribute_grid.height)

func reset_from_data(data: Array2D) -> void:
	_attribute_grid = data 
	update_tile_map()

#removes every attribute from a tile that is in data
#only removes from tiles that match item_id with item_id_value
#TODO: refactor this function to be more clear
func remove_attributes(data: Dictionary[String, Variant], item_id: String, item_id_value: Variant) -> void: 
	for x in get_width():
		for y in get_height():
			var tile_attributes = _attribute_grid.getItem(x, y)
			if tile_attributes is Dictionary:
				#if the tile is identified as the tile type in question
				if (tile_attributes.has(item_id) and 
					(tile_attributes[item_id] is Array and tile_attributes[item_id].has(item_id_value) or 
					tile_attributes[item_id] is not Array and tile_attributes[item_id] == item_id_value)):
						#remove every key that exists in the data from the tile
					for key in data:
						if not tile_attributes.has(key):
							continue
						var val = tile_attributes[key]
						var remove_val = data[key]
						if val is Array:
							val = val.filter(func(v): return v != remove_val)
							if val.is_empty():
								tile_attributes.erase(key)
							else:
								tile_attributes[key] = val
						elif val == remove_val:
							tile_attributes.erase(key)
	update_tile_map()

func sync_attributes(data: Dictionary[String, Variant], item_id: String, item_id_value: Variant) -> void: 
	for x in get_width():
		for y in get_height():
			var tile_attributes = _attribute_grid.getItem(x, y)
			if tile_attributes is Dictionary:
				#if the tile is identified as the tile type in question
				if (tile_attributes.has(item_id) and 
					(tile_attributes[item_id] is Array and tile_attributes[item_id].has(item_id_value) or 
					tile_attributes[item_id] is not Array and tile_attributes[item_id] == item_id_value)):
						for key in data:
							if tile_attributes[key] is Array: 
								if !tile_attributes[key].has(data[key]):
									tile_attributes[key].append(data[key])
							else:
								tile_attributes[key] = data[key]

									
	update_tile_map()

#if ERASE -> changes the hovered tile source id to -1 so it becomes blank
func erase_tile(hovered_tile: Vector2i) -> void: 
	var empty_attribute_list: Dictionary[String, Variant] = {}
	_attribute_grid.setItem(hovered_tile.x, hovered_tile.y, empty_attribute_list)
	_tile_map_layer.set_cell(hovered_tile, -1)

#removes tile from the map with specific tile_id value
#updates th _attribute_grid
#then updates the tile_map based on the attribute grid
func remove_tiles(tile_id_value: Variant) -> void: 
	for x in _attribute_grid.width:
		for y in _attribute_grid.height:
			var tile_attributes = _attribute_grid.getItem(x, y)
			if tile_attributes.has(_tile_id) and tile_attributes[_tile_id] == tile_id_value:
				var empty_attribute_list: Dictionary[String, Variant] = {}
				_attribute_grid.setItem(x, y, empty_attribute_list)
	update_tile_map()

##setters / Getters
func get_tile_texture_id() -> Variant:
	return _tile_texture_id
	
func get_tile_id() -> Variant:
	return _tile_id

func set_attribute_grid(new_grid: Array2D) -> void: 
	_attribute_grid = new_grid

func get_width() -> int:
	return _attribute_grid.width
	
func get_height() -> int:
	return _attribute_grid.height
	
