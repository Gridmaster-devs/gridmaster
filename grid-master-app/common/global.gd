extends Node

## Universal variables used in editors and executioner
const tile_width = 64
const tile_height = 64

const unit_width = 32
const unit_height = 32

enum GameType {SINGLEPLAYER, MULTIPLAYER}
var game_type = null

##popup manager
var popup_manager: PopupManager = null
