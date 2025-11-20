@tool
extends PanelContainer
@export_group("Sections")
@export var section_headers : Array[String]
@export_tool_button("Update", "Callable") var update_action : Callable = update_headers


func update_headers():
	if Engine.is_editor_hint():
		var content_box = get_node("TopVBox/ScrollContainer/ContentsVBox")
		for child in content_box.get_children():
			content_box.remove_child(child)
		for title in section_headers:
			var label = Label.new()
			label.set_name(title)
			label.text = title
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			content_box.add_child(label, true)
			label.owner = get_tree().edited_scene_root
			label.theme_type_variation = "SectionLabel"
