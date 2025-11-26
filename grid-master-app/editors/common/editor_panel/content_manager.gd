@tool
extends PanelContainer

@export var title : String

@export_category("Contents")
@export_group("Sections")
@export var section_headers : Array[String]
@export_group("")

@export_category("Update")
@export_tool_button("Update Panel", "Callable") var update_action : Callable = update_panel

var sub_sections : Dictionary[String, Node] = {}

func update_panel():
	if Engine.is_editor_hint():
		update_name()
		update_headers()

func update_name():
	if Engine.is_editor_hint():
		var top_label : Label = get_node("TopVBox/TopLabel")
		if title.is_empty():
			title = self.name
		print("Title is " + title)
		top_label.text = title
	

func update_headers():
	if Engine.is_editor_hint():
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
			
func _ready():
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE
