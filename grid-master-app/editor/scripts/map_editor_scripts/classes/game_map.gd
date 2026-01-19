class_name GameMap
extends Resource 

#an array of source ids
@export var grid: Grid
#a map from source ids to their tactical maps
@export var tactical_grid_strategic_tile_map: Dictionary[int, String] = {} 
#maps tactical grid names to corresponding grids
@export var tactical_grid_map: Dictionary[String, Grid]
#a map from source ids to corresponding tactical tile information
@export var tactical_tile_information_map: Dictionary[int, TacticalTileInformation] = {}
#a map from source ids to corresponding strategic tile information
@export var strategic_tile_information_map: Dictionary[int, StrategicTileInformation] = {}
#an array that maps the tile textures to corresponding ids
@export var texture_map: Dictionary[int, Texture2D] = {}
#a dictionary that maps source ids to tactical map thumbnails
@export var tactical_grid_thumbnail_texture_map: Dictionary[String, Texture2D] 
