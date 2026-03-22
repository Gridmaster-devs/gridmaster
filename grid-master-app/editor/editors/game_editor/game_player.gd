class_name GamePlayer



var _name: String
var _id: int
var _team: GameTeam


func _init(name: String, id: int, team: GameTeam) -> void: 
	_name = name
	_id = id
	_team = team

func get_team() -> GameTeam: 
	return _team

func set_team(new_team: GameTeam) -> void: 
	_team = new_team

func set_name(new_name: String) -> void:
	_name = new_name


func get_name() -> String: 
	return _name


func get_id() -> int:
	return _id
