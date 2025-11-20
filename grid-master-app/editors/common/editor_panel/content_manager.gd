@tool
extends PanelContainer

@export var title : String

@export_category("Contents")
@export_group("Sections")
@export var section_headers : Array[String]
@export_group("")

@export_category("Update")
@export_tool_button("Update Panel", "Callable") var update_action : Callable = update_panel

func update_panel():
	if Engine.is_editor_hint():
		update_name()
		update_headers()

func update_name():
	if Engine.is_editor_hint():
		var top_label : Label = get_node("TopVBox/TopLabel")
		if title.is_empty():
			print("Empty title")
			title = self.name
		print("Title is " + title)
		top_label.text = title
	

func update_headers():
	if Engine.is_editor_hint():
		var content_box : VBoxContainer = get_node("TopVBox/ScrollContainer/ContentsVBox")
		for child in content_box.get_children():
			content_box.remove_child(child)
		for h in section_headers:
			var label = Label.new()
			label.set_name(h)
			label.text = h
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			content_box.add_child(label, true)
			label.owner = get_tree().edited_scene_root
			label.theme_type_variation = "SectionLabel"
