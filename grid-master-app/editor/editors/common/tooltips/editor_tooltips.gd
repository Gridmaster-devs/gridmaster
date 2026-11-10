@tool
class_name EditorTooltips
extends RefCounted

const TEXT := {
  "unit": {
    "name": "The name shown for this unit type.",
    "texture": "The image used to represent this unit.",
    "movement_type": "How this unit moves across the map.",
    "movement_speed": "How far the unit can move each turn. Different terrain costs different amounts of movement points, and faster units move first",
    "capturable": "Whether this unit can be captured by another player.",
    "is_producible_unit": "Whether this unit can be produced by other units.",
    "production_cost": "How many turns it takes to produce this unit.",
    "is_production_unit": "Whether this unit can produce other units.",
    "producible_units": "Which unit types this unit can produce.",
    "health": "How much damage the unit can take before being destroyed.",
    "morale": "The unit's starting morale.",
    "victory_points": "How many victory points this unit is worth.",
    "attack": "How much damage this unit deals when it hits.",
    "armor_piercing": "How much armor this unit can penetrate.",
    "accuracy": "How likely this unit is to hit its target.",
    "attack_range": "How far this unit can attack (in tiles).",
    "armor": "How much armor protects this unit from attacks.",
    "evasion": "How likely this unit is to dodge an attack.",
    "vision_range": "How far the unit will see (in tiles).",
    "perception": "How well this unit can detect hidden enemies.",
    "action_name": "The name of this action.",
    "action_type": "The kind of action this unit can perform.",
    "consumed_resource": "Which resource this action consumes.",
    "consumed_amount": "How much of the resource this action consumes.",
    "produced_resource": "Which resource this action produces.",
    "produced_amount": "How much of the resource this action produces.",
    "unit_list": "Choose a unit to view or edit.",
    "add_unit": "Create a new unit type.",
    "remove_unit": "Remove the selected unit type.",
    "save_unit": "Save the selected unit to a file.",
    "load_unit": "Load a unit from a file.",
    "add_action": "Add an action to this unit.",
    "remove_action": "Remove this action from the unit.",
    "producible_units_add": "Add the selected unit type to the production list.",
    "producible_units_remove": "Remove this unit type from the production list."
  },
  "map": {
    "width": "How many tiles wide the map is.",
    "height": "How many tiles tall the map is.",
    "map_name": "The name shown for this map.",
    "save_name": "The name to use when saving this map.",
    "tile.name": "The name of this terrain type.",
    "tile.protection": "How much this terrain reduces damage to defending units.",
    "tile.movement": "How many movement points it costs to enter this terrain.",
    "tile.hiding": "How much concealment this terrain provides.",
    "tile.texture": "The image used to display this terrain.",
    "save_map": "Save the current map.",
    "load_map": "Load a previously saved map.",
    "map_mode": "Switch between strategic and tactical maps.",
    "save_name_confirm": "Save the map with the chosen name.",
    "tactical_map": "The tactical map associated with this location.",
    "tactical_map_thumbnail": "The preview image for this tactical map."
  },
  "painter": {
    "settings": "Change the map size and name.",
    "erase": "Erase tiles by clicking or dragging on the map.",
    "interact": "Click a tile to view its properties.",
    "library_tile": "Choose what to paint onto the map.",
    "new_library_tile": "Create a new tile type.",
    "remove_library_tile": "Remove the selected tile type.",
    "choose_color": "Use a solid color for this tile.",
    "choose_image": "Choose an image for this tile.",
    "crop_image": "Crop the selected tile image.",
    "tile_description_value": "The properties of the selected tile.",
    "tile_create_save": "Add this tile type to the library.",
    "tile_create_cancel": "Close without adding the tile.",
    "settings_save": "Apply these map settings.",
    "settings_cancel": "Close without applying changes."
  },
  "game": {
    "game_name": "The name of your game.",
    "team_name": "The name of this team.",
    "team_color": "The color used to identify this team and its units.",
    "team_unit_selection": "Choose which unit types are available to this team.",
    "player_name": "The name of this player.",
    "player_team": "Choose which team this player belongs to.",
    "player_key_unit": "The unit type this player must keep alive to avoid elimination. Leave blank to count any surviving unit.",
    "combat_rounds": "How many rounds of attacks can occur in one fight.",
    "save_game": "Save this game setup to a file.",
    "load_game": "Load a saved game setup.",
    "new_team": "Add a new team.",
    "new_player": "Add a new player.",
    "unit_placement": "Select a unit, then click the map to place it."
  }
}

const WARNINGS := {
 "unit": ["movement_type", "capturable", "victory_points", "perception", "is_producible_unit", "action_name", "action_type", "consumed_resource", "consumed_amount", "produced_resource", "produced_amount"],
 "map": ["tile.hiding", "tactical_map"],
 "painter": ["crop_image"],
}
const WARNING_TEXT := "Not yet used in gameplay"

static func get_tooltip(context: String, key: String) -> String:
 return TEXT.get(context, {}).get(key, "")

static func has_warning(context: String, key: String) -> bool:
 return key in WARNINGS.get(context, [])
