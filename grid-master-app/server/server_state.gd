extends Node

# The ServerState class tracks everything related to the game's
# and the server's state, so that the state can be saved and
# later loaded from a file that has been saved on the disk.
#
# The name ServerState is actually a misnomer since this class
# represents the state of the game as a whole, but since GameState
# name is already taken, this is the second best one.
#
# There are three ways to initialize a ServerState instance:
# 1. _init() and through its arguments
# 2. new() which creates a new, empty ServerState object
# 3. load() which loads a saved ServerState object from the disk
class ServerState:
	var game_definition: GameDefinitionResource
	var game_state: GameState
	var data_manager: GameDataManager
	var current_turn: int

	# peer_id - team_id mapping
	var clients: Dictionary[int, int] = {}
	var teams_ended_turn: Array[int] = []

	func _init(game_definition: GameDefinitionResource) -> void:
		self.game_definition = game_definition
		self.game_state = GameState.initFromGameDefinition(game_definition)
		self.current_turn = 1

	# Add client_id to clients
	func join(client_id: int) -> void:
		if clients.keys().has(client_id):
			GML.log("Client %d has been already added to the list of clients.", GML.LogLevel.ERROR)
		else:
			clients[client_id] = TEAM_ID_NOT_SELECTED

	func active_clients() -> int:
		return clients.size()

	func join_team(peer_id: int, team_id: int) -> void:
		if !clients.keys().has(peer_id):
			GML.log("Client %d is already part of a team.", GML.LogLevel.ERROR)
		else:
			clients[peer_id] = team_id

	func total_teams() -> int:
		return game_definition.team_uis.size()

	func teams_ended() -> int:
		return teams_ended_turn.size()

	func get_player_team_nullable(peer_id: int) -> Team:
		if clients.keys().has(peer_id) and game_state.teams.keys().has(clients[peer_id]):
			return game_state.teams[clients[peer_id]]
		return null

	#func is_player_in_team(peer_id: int, team_name: String) -> bool:
		#var player_team: TeamInfo = get_player_team_nullable(peer_id)
		#return player_team and player_team.name == team_name

	func end_team_turn(team_id: int) -> void:
		teams_ended_turn.append(team_id)

	# Clear the array tracking all the team_id's that have ended their turns.
	func clear_turns() -> void:
		teams_ended_turn.clear()

	func team_has_ended_turn(team_id: int) -> bool:
		# TODO: Make sure this works.
		return teams_ended_turn.has(team_id)

# TODO: Return a game state that can be transfered via the network interface
	func get_serialized_game_change() -> Dictionary:
		# TODO: Implement
		return {}

	func save(path: String) -> void:
		# TODO: Implement
		pass

	#static func load(path: String) -> ServerState:
		## TODO: Implement
		#pass

# Note: ClientInfo is NOT considered a part of the ServerState,
# since the peer_id will change every time a player joins the game.
#
# Instead, with the new implementation the player always selects the
# team after they connect to the server.
const TEAM_ID_NOT_SELECTED = -1
class ClientInfo:
	var teamId: int
	
	func _init(teamId: int) -> void:
		self.teamId = teamId
	
	func serialize() -> Dictionary:
		return {
			"team_id": teamId
		}
