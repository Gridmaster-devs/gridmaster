extends GutTest

const UNIT_EDITOR_PATH = "res://editors/unit_editor/UnitEditor.tscn"
# Temporary file path.
const TEST_RESOURCE_PATH = "user://test_unit_resource.tres"

var unit_editor: UnitEditor

func before_each():
	# Clean up any existing file
	if FileAccess.file_exists(TEST_RESOURCE_PATH):
		DirAccess.remove_absolute(TEST_RESOURCE_PATH)
	
	# Instantiate the editor
	if ResourceLoader.exists(UNIT_EDITOR_PATH):
		var scene = load(UNIT_EDITOR_PATH)
		unit_editor = scene.instantiate()
		add_child(unit_editor)
		# Wait for _ready and signal connection
		await wait_process_frames(2)

func after_each():
	# Clean up
	if is_instance_valid(unit_editor):
		unit_editor.queue_free()
	if FileAccess.file_exists(TEST_RESOURCE_PATH):
		DirAccess.remove_absolute(TEST_RESOURCE_PATH)

# TODO: Should these be separated.
func test_load_resource_functionality():
	# Ensure editor is loaded
	if unit_editor == null:
		fail_test("UnitEditor scene failed to load")
		return

	# Create a UnitResourceDict and save it to a file
	var unit_resource = UnitResourceDict.new()
	var unit_name = "Test Unit 123"
	unit_resource.set_attribute("name", unit_name)
	
	# Save the unit resource
	var err = ResourceSaver.save(unit_resource, TEST_RESOURCE_PATH)
	assert_eq(err, OK, "Resource saving should succeed")
	
	# Verify the file exists
	assert_true(FileAccess.file_exists(TEST_RESOURCE_PATH), "Test resource file should exist")
	
	# Count units before
	var initial_units_count = unit_editor.get_units().size()
	
	# Load the resource from the file
	unit_editor.load_from_file(TEST_RESOURCE_PATH)
	
	# Verify that the unit was added
	var units = unit_editor.get_units()
	assert_eq(units.size(), initial_units_count + 1, "Should have one more unit after loading")
	
	# 4. Verify the content of the loaded unit
	var loaded_unit = units[units.size() - 1]
	assert_eq(loaded_unit.get_attribute_value("name"), unit_name, "Loaded unit name should match")

# TODO: Test that only known types are loaded, otherwise expect error.
