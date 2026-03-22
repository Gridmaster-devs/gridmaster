class_name MapAttributes

##SHOULD BE USED FOR MAP PAINTER CONFIGS
##IF YOU MAKE A NEW MAP PAINTER ADD THE CONFIGURATION VARIABLES HERE

#each Map Painter needs the following:
#tile id (to identify unique tile types)
#texture id (if for the texture that shows on the map)

#library information for every library:
#library name
#library item_id (to identify unique library items, this can match tile id) 
#library texture_id (to identify what texture in the attribute list is shown on the library ui) 
#library overwrite (attributes that are overwritten on paint) (should be ids matched with empty types)
#library add (attributes that are added on paint) (should be ids matched with empty types)



##STRATEGIC
const STRATEGIC_TILE_ID: String = "name"
const STRATEGIC_TEXTURE_ID: String = "texture"


const STRATEGIC_TILE_LIB_NAME: String = "Strategic Tile Library"
const STRATEGIC_TILE_LIB_ITEM_ID: String = "name"
const STRATEGIC_TILE_LIB_TEXTURE_ID: String = "texture"

const STRATEGIC_TACTICAL_LIB_NAME: String = "Tactical Library"
const STRATEGIC_TACTICAL_LIB_ITEM_ID: String = "tactical_map"
const STRATEGIC_TACTICAL_LIB_TEXTURE_ID: String = "tactical_map_thumbnail"



static var STRATEGIC_TILE_LIB_ALL_ATTRIBUTES: Dictionary[String, Variant] = {
		"name": String(), "protection": int(), "movement": int(), "hiding": int(), 
	"texture": Texture2D.new()}

static var STRATEGIC_TILE_LIB_ADD: Dictionary[String, Variant] = {}

static var STRATEGIC_TILE_LIB_OVERWRITE: Dictionary[String, Variant] = {
		"name": String(), "protection": int(), "movement": int(), "hiding": int(), 
	"texture": Texture2D.new()}

static var STRATEGIC_TACTICAL_LIB_OVERWRITE:  Dictionary[String, Variant] = {
		"tactical_map": String(), "tactical_map_thumbnail": Texture2D.new()}
		
static var STRATEGIC_TACTICAL_LIB_ADD: Dictionary[String, Variant] = {}


##TACTICAL
const TACTICAL_TILE_ID: String = "name"
const TACTICAL_TEXTURE_ID: String = "texture"

const TACTICAL_TILE_LIB_NAME: String = "Tactical Tile Library"
const TACTICAL_TILE_LIB_ITEM_ID: String = "name"
const TACTICAL_TILE_LIB_TEXTURE_ID: String = "texture"

static var TACTICAL_TILE_LIB_ADD: Dictionary[String, Variant] = {}

static var TACTICAL_TILE_LIB_OVERWRITE: Dictionary[String, Variant] = {
		"name": String(), "protection": int(), "movement": int(), "hiding": int(), 
	"texture": Texture2D.new()}


##UNIT
const UNIT_TILE_ID: String = "name"
const UNIT_TEXTURE_ID: String = "unit_texture"
const UNIT_TEAM_ID: String = "team"
const UNIT_PLAYER_ID: String = "player"


const UNIT_UNIT_LIB_ITEM_ID: String = "unit"
const UNIT_UNIT_LIB_TEXTURE_ID: String = "unit_texture"


static var UNIT_UNIT_LIB_ADD: Dictionary[String, Variant] = {}

static var UNIT_UNIT_LIB_OVERWRITE: Dictionary[String, Variant] = {"unit": String(), "unit_texture": Texture2D, 
																	"team": String(), UNIT_PLAYER_ID: String()}







#
