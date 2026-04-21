class_name TeamSelectGUI
extends GUIScene

@onready var _teams_container : VBoxContainer = $TeamsContainer
@onready var _status_label : Label = $StatusLabel

var _teams_data: Array = []

func set_status(status_text: String):
	if _status_label:
		_status_label.text = status_text


func populate_teams(teams: Array):
	_teams_data = teams
	
	# Clear existing buttons
	for child in _teams_container.get_children():
		child.queue_free()
	
	# Create a button for each team
	# TODO: Don't use iterator
	for i in range(teams.size()):
		var team = teams[i]
		var button = Button.new()
		button.text = team.get("name", "Team %d" % i)
		button.custom_minimum_size = Vector2(300, 60)
		
		# Set button color based on team color
		var color_str = team.get("color", "#FFFFFF")
		var color = Color.from_string(color_str, Color.WHITE)
		button.add_theme_color_override("font_color", color)
		
		# Connect button press
		button.pressed.connect(_on_team_button_pressed.bind(team.get("id")))
		
		_teams_container.add_child(button)
	
	set_status("Select your team")


func _on_team_button_pressed(team_id: int):
	set_status("Joining team %d..." % team_id)
	send_gm_signal(ButtonPressedEvent.new(ButtonPressedEvent.ButtonType.SELECT_TEAM, team_id))


func _ready() -> void:
	pass


func initialize(args : Variant) -> void:
	if args is Array:
		populate_teams(args)
