class_name ServerState
extends RefCounted

## The ServerState class tracks everything related to the game's
## and the server's state, so that the state can be saved and
## later loaded from a file that has been saved on the disk.
##
## The name ServerState is actually a misnomer since this class
## represents the state of the game as a whole, but since GameState
## name is already taken, this is the second best one.
##
## There are three ways to initialize a ServerState instance:
## 1. _init() and through its arguments
## 2. new() which creates a new, empty ServerState object
## 3. load() which loads a saved ServerState object from the disk

var game_definition_resource: GameDefinitionResource
var data_manager: GameDataManager
var current_turn: int

## peer_id - team_id mapping
var clients: Dictionary[int, int] = {}
## peer_id - game player_id mapping (first player on the joined team)
var peer_player_ids: Dictionary[int, int] = {}
var teams_ended_turn: Array[int] = []
var players_ended_turn: Array[int] = []
var eliminated_players: Array[int] = []
var game_over: bool = false
var winner_player_id: int = -1

# FIFO queue for turn messages
var _message_queue: Array[String] = []

func _init(game_definition: GameDefinitionResource) -> void:
	self.game_definition_resource = game_definition
	self.data_manager = GameDataManager.initFromGameDefinition(game_definition)
	self.current_turn = 1

## Add client_id to clients
func join(client_id: int) -> void:
	if clients.keys().has(client_id):
		GML.log("Client %d has been already added to the list of clients.", GML.LogLevel.ERROR)
	else:
		clients[client_id] = TEAM_ID_NOT_SELECTED

func active_clients() -> int:
	return clients.size()

func assign_peer_to_team(peer_id: int, team_id: int) -> void:
	if !clients.keys().has(peer_id):
		GML.log("Client %d is not connected." % peer_id, GML.LogLevel.ERROR)
		return
	clients[peer_id] = team_id
	peer_player_ids[peer_id] = _get_first_player_id_for_team(team_id)

func _get_first_player_id_for_team(team_id: int) -> int:
	for player: Player in data_manager.get_players().values():
		if player.team != null and player.team.team_id == team_id:
			return player.player_id
	return -1

func get_peer_player_id(peer_id: int) -> int:
	return peer_player_ids.get(peer_id, -1)

func total_teams() -> int:
	return game_definition_resource.team_uis.size()

func teams_ended() -> int:
	return teams_ended_turn.size()

func is_player_eliminated(player_id: int) -> bool:
	return eliminated_players.has(player_id)

func mark_player_eliminated(player_id: int) -> void:
	if not eliminated_players.has(player_id):
		eliminated_players.append(player_id)

## A connected peer is alive when their mapped player is not eliminated.
func is_peer_alive(peer_id: int) -> bool:
	var player_id := get_peer_player_id(peer_id)
	if player_id < 0:
		return true
	return not is_player_eliminated(player_id)

func players_ended() -> int:
	return players_ended_turn.size()

func mark_player_end_turn(peer_id: int) -> void:
	if not players_ended_turn.has(peer_id):
		players_ended_turn.append(peer_id)

func clear_player_turns() -> void:
	players_ended_turn.clear()

func is_peer_finished(peer_id: int) -> bool:
	if clients[peer_id] == TEAM_ID_NOT_SELECTED:
		return false
	if not is_peer_alive(peer_id):
		return true
	var player_id := get_peer_player_id(peer_id)
	if player_id >= 0 and is_player_eliminated(player_id):
		return true
	if player_id >= 0:
		var player: Player = data_manager.get_players().get(player_id)
		if player != null and not GameElimination.player_has_key_units(player, data_manager.get_units()):
			if not is_player_eliminated(player_id):
				mark_player_eliminated(player_id)
				push_message("%s has been eliminated." % player.player_name)
			return true
	return players_ended_turn.has(peer_id)

func are_all_peers_finished() -> bool:
	for peer_id in clients.keys():
		if not is_peer_finished(peer_id):
			return false
	return true

func get_player_team_nullable(peer_id: int) -> Team:
	if clients.keys().has(peer_id) and data_manager.get_teams().keys().has(clients[peer_id]):
		return data_manager.get_teams()[clients[peer_id]]
	return null

func process_eliminations_and_victory() -> void:
	if game_over:
		return
	var players := data_manager.get_players()
	var units := data_manager.get_units()
	for player_id in GameElimination.get_newly_eliminated(players, units, eliminated_players):
		mark_player_eliminated(player_id)
		var player: Player = players[player_id]
		push_message("%s has been eliminated." % player.player_name)
	if game_over:
		return
	var winner := GameElimination.get_winner_player_id(players, units, eliminated_players)
	if winner >= 0:
		game_over = true
		winner_player_id = winner
		var winner_player: Player = players[winner]
		push_message("%s wins!" % winner_player.player_name)
	elif GameElimination.get_players_with_key_units(players, units, eliminated_players).is_empty():
		game_over = true
		winner_player_id = -1
		push_message("Draw — no players remain.")

func end_team_turn(team_id: int) -> void:
	teams_ended_turn.append(team_id)

func clear_turns() -> void:
	teams_ended_turn.clear()

func get_message_queue() -> Array[String]:
	return _message_queue

func push_message(message: String) -> void:
	_message_queue.push_back(message)

func clear_message_queue() -> void:
	_message_queue.clear()

func team_has_ended_turn(team_id: int) -> bool:
	return teams_ended_turn.has(team_id)

func get_serialized_game_change() -> Dictionary:
	return {}

func save(path: String) -> void:
	pass

const TEAM_ID_NOT_SELECTED = -1
class ClientInfo:
	var teamId: int
	
	func _init(teamId: int) -> void:
		self.teamId = teamId
	
	func serialize() -> Dictionary:
		return {
			"team_id": teamId
		}
