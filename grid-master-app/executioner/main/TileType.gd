class_name TileType
## Class that represents a type of tile on the map

# NOTE: In the future we might have to implement a system where some units
# can get an upgrade to improve their movement on a certain type of tile
# ex. faster movement in swamps
enum TILE_ATTRIBUTE_TYPE{MOVEMENT, PROTECTION, HIDING}

var type_id : int ## ID of the tile type
var tile_name : String ## Name of the tile type
var description : String ## Description of the tile type
var texture : Texture2D ## Texture used for drawing the tile

# these are the same as in unit type
# the modifiers might be unnecessary for now
var attributes : Dictionary[TILE_ATTRIBUTE_TYPE, int]
var flat_modifiers : Dictionary[TILE_ATTRIBUTE_TYPE, float]
var percentage_modifiers : Dictionary[TILE_ATTRIBUTE_TYPE, float]


## creates a debug tile for testing
static func debugTile() -> TileType:
	var tile_type = TileType.new()
	tile_type.type_id = -1
	tile_type.tile_name = "Debug tile"
	tile_type.description = "Tile for testing"
	return tile_type
