class_name FileTransferManager
extends Node
## Class that handles file downloads and uploads, on the web and locally

signal file_uploaded(file_data : PackedByteArray, cancelled : bool)

var process_ongoing : bool = false ## Whether we have a file dialog open right now
var current_dialog : FileDialog ## Reference to the current file dialog if there is one so it can be freed
var current_data : Variant ## Reference to the current resource that is being downloaded
var is_type_resource : bool ## Whether the uploaded / downloaded data is a resource

var current_faw : FileAccessWeb ## Reference to the current file access web object for uploading


## Returns the signal that is emitted when the user uploads
## (or fails to uplaod) a file
func get_upload_signal() -> Signal:
	return file_uploaded


## Prompts the user for a download of a file with a specific content and filename
func download_data(input_data : Variant, default_filename : String, filetypes : String, resource : bool) -> void:
	# If build is running in the browser
	if (OS.has_feature("web") == true):
		var data : PackedByteArray = var_to_bytes_with_objects(input_data)
		JavaScriptBridge.download_buffer(data, default_filename)

	# If build is not running in the browser
	else:
		# If we already have a file dialog window open, we shouldn't open another one
		if (process_ongoing == true): return
		
		process_ongoing = true
		if (resource == true): is_type_resource = true
		var dialog := FileDialog.new()
		
		dialog.access = FileDialog.ACCESS_FILESYSTEM # User can save to anywhere in the filesystem
		dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE # User is prompted to save a file
		dialog.display_mode = FileDialog.DISPLAY_LIST # Files will be shown as a list and not as thumbnails
		dialog.add_filter(filetypes) # Filter how the file can be saved
		
		dialog.file_selected.connect(_finish_local_download) # If the user selects a file
		dialog.close_requested.connect(_process_done) # If the user closes the dialog window
		current_dialog = dialog
		current_data = input_data
		self.add_child(dialog) # I don't know if this is even necessary to show the dialog box to the user?
		dialog.show()


## Finishes the local download
##
## Called by the dialog window when a filepath is selected
func _finish_local_download(path : String) -> void:
	if (is_type_resource == true):
		ResourceSaver.save(current_data, path)
	else:
		var file = FileAccess.open(path, FileAccess.WRITE)
		file.store_buffer(var_to_bytes_with_objects(current_data))

	_process_done()


## Gives the user an upload window to upload a file
##
## You MUST connect to the file_uploaded signal before you call this function
func upload_data(filetypes : String, resource : bool) -> void:
	# if we have another upload / download already going
	if (process_ongoing == true): return
	process_ongoing = true
	
	if (resource == true): is_type_resource = true
	
	# If build is running in the browser
	if (OS.has_feature("web")):
		var file_access_web = FileAccessWeb.new()
		current_faw = file_access_web
		current_faw.loaded.connect(_finish_web_upload)
		current_faw.upload_cancelled.connect(_web_upload_cancelled)
		current_faw.error.connect(_web_upload_cancelled)
		current_faw.open(filetypes)


	# If build is not running in the browser
	else:
		var dialog := FileDialog.new()
		
		dialog.access = FileDialog.ACCESS_FILESYSTEM # User can upload from anywhere in the filesystem
		dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE # User is prompted to open a file
		dialog.display_mode = FileDialog.DISPLAY_LIST # Files will be shown as a list and not as thumbnails
		dialog.add_filter(filetypes) # Filter which filetypes can be uploaded
		
		dialog.file_selected.connect(_finish_local_upload) # If the user selects a file
		dialog.close_requested.connect(_process_done) # If the user closes the dialog window
		current_dialog = dialog
		self.add_child(dialog) # I don't know if this is even necessary to show the dialog box to the user?
		current_dialog.show()


func _finish_web_upload(_file_name : String, _file_type : String, file_data : String) -> void:
	file_uploaded.emit(var_to_bytes(file_data), false)
	
	_process_done()


func _web_upload_cancelled():
	file_uploaded.emit(PackedByteArray(), true) # There was some error
	
	_process_done()


func _finish_local_upload(path : String) -> void:
	var data = FileAccess.get_file_as_bytes(path)
	if (data != null):
		file_uploaded.emit(data, false)
	else:
		file_uploaded.emit(PackedByteArray(), true)
	
	_process_done()
	

## Frees the dialog box
##
## Called by either the dialog box when closed or by the
## finish local download function
func _process_done() -> void:
	process_ongoing = false
	if (current_dialog != null):
		current_dialog.queue_free()
	current_dialog = null
	current_faw = null
	current_data = null
	is_type_resource = false


func _init() -> void:
	pass
