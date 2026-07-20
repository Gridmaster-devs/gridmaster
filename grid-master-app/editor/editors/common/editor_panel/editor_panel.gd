@tool
class_name EditorPanel
extends PanelContainer
## A modular UI panel for building editors
##
## The tool script allows one to easily add, remove, and reorder subheaders
## of the panel, as well as change the name of the panel.

signal close_button_pressed

## The title of the panel.
@export var title : String

@export_category("Contents")
@export_group("Sections")
## Determines the order, names, and count of the subheaders.
@export var section_headers : Array[String]
@export_group("")

@export var has_close_button: bool = false

@export_category("Update")
## The action triggered by the "Update Panel" button in the Inspector panel.
@export_tool_button("Update Panel", "Callable") var update_action : Callable = update_panel

@onready var header_node = $TopVBox/TopLabel

var close_button_scene = preload("res://editor/editors/common/editor_panel/editor_panel_close_button.tscn")

## A dictionary storing the subheader nodes by their display text.
var sub_sections : Dictionary[String, Node] = {}

## Calls func update_name() and func update_headers()
func update_panel():
	update_name()
	update_headers()

## Updates the panel's name on the top header.
func update_name():
	var top_label : Label = get_node("TopVBox/TopLabel")
	if title.is_empty():
		title = self.name
	top_label.text = title
	
## Updates the subheaders of the panel. It can reorder existing headers while maintaining their
## children, but changing the name of a header will render it a new header, deleting its children.
func update_headers():
	var content_box : VBoxContainer = get_node("TopVBox/ScrollContainer/ContentsVBox")
	var i = 0
	for h in section_headers:
		var section : Node = sub_sections.get(h, VBoxContainer.new())
		if section.get_parent() == content_box:
			content_box.move_child(section, i)
		else:
			var label = Label.new()
			section.set_name(h)
			label.text = h
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			section.add_child(label, true)
			content_box.add_child(section, true)
			section.owner = get_tree().edited_scene_root
			label.owner = get_tree().edited_scene_root
			label.theme_type_variation = "SectionLabel"
			content_box.move_child(section, i)
			sub_sections.get_or_add(h, section)
		i += 1
	for over_max in range(i, content_box.get_child_count()):
		var removed = content_box.get_child(i)
		sub_sections.erase(removed.name)
		content_box.remove_child(removed)
		
func _on_close_button_pressed():
	close_button_pressed.emit()

# Called on loading the scene tree (or when the node enters the scene tree).
# Gives the panel its pre-existing subheaders, as var sub_sections is reset between
# instantiations.
func _ready() -> void:
	section_headers = []
	var content_box : VBoxContainer = get_node("TopVBox/ScrollContainer/ContentsVBox")
	var headers : Array[Node] = content_box.get_children()
	for header in headers:
		section_headers.append(header.name)
		sub_sections.get_or_add(header.name, header)
		print("Added header " + header.name)
	if has_close_button:
		var close_button = close_button_scene.instantiate()
		header_node.add_child(close_button)
		close_button.pressed.connect(_on_close_button_pressed)
