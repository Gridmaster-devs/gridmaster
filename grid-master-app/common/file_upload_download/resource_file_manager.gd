class_name ResourceFileManager
extends Node
## Class that handles file downloads and uploads, on the web and locally

const ALLOWED_FILETYPES : String = "*.tres, *.res"

var process_ongoing : bool = false ## Whether we have a file dialog open right now
var current_dialog : FileDialog ## Reference to the current file dialog if there is one so it can be freed
var current_resource : Resource ## Reference to the current resource that is being downloaded

var current_faw : FileAccessWeb ## Reference to the current file access web object for uploading
var current_local_upload_signal : Signal


## Prompts the user for a download of a file with a specific content and filename
func download_resource(resource : Resource, default_filename : String) -> void:
	# If build is running in the browser
	if (OS.has_feature("web") == true):
		var data : PackedByteArray = var_to_bytes_with_objects(resource)
		JavaScriptBridge.download_buffer(data, default_filename)

	# If build is not running in the browser
	else:
		# If we already have a file dialog window open, we shouldn't open
		# another one
		if (process_ongoing == true): return
		
		process_ongoing = true
		var dialog := FileDialog.new()
		
		dialog.access = FileDialog.ACCESS_FILESYSTEM # User can save to anywhere in the filesystem
		dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE # User is prompted to save a file
		dialog.display_mode = FileDialog.DISPLAY_LIST # Files will be shown as a list and not as thumbnails
		dialog.add_filter(ALLOWED_FILETYPES, "Resource files") # Filter how the file can be saved
		
		dialog.file_selected.connect(_finish_local_download) # If the user selects a file
		dialog.close_requested.connect(_process_done) # If the user closes the dialog window
		current_dialog = dialog
		current_resource = resource
		self.add_child(dialog) # I don't know if this is even necessary to show the dialog box to the user?
		dialog.show()


## Finishes the local download
##
## Called by the dialog window when a filepath is selected
func _finish_local_download(path : String) -> void:
	ResourceSaver.save(current_resource, path)
	_process_done()


func initialize_upload() -> Variant:
	# If build is running in the browser
	if (OS.has_feature("web")):
		var file_access_web = FileAccessWeb.new()
		current_faw = file_access_web
		return current_faw.loaded


	# If build is not running in the browser
	else:
		if (process_ongoing == true): return null
		process_ongoing = true
		
		var dialog := FileDialog.new()
		
		dialog.access = FileDialog.ACCESS_FILESYSTEM # User can save to anywhere in the filesystem
		dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE # User is prompted to save a file
		dialog.display_mode = FileDialog.DISPLAY_LIST # Files will be shown as a list and not as thumbnails
		dialog.add_filter(ALLOWED_FILETYPES, "Resource files") # Filter how the file can be saved
		
		dialog.file_selected.connect(_finish_local_upload) # If the user selects a file
		dialog.close_requested.connect(_process_done) # If the user closes the dialog window
		current_dialog = dialog
		self.add_child(dialog) # I don't know if this is even necessary to show the dialog box to the user?
		dialog.show()


func _finish_local_upload(path : String) -> void:
	pass

## Frees the dialog box
##
## Called by either the dialog box when closed or by the
## finish local download function
func _process_done() -> void:
	process_ongoing = false
	current_dialog.queue_free()
	current_dialog = null
	current_resource = null


func _init() -> void:
	pass
