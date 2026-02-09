extends Node
## GML, which stands for Game Master Logger

# this isn't very good and we should probably just use the built in
# godot logging tools

var log_dir = "res://logs/"
var date : String
var logfile : FileAccess
var init_done : bool = false


func log(message : String) -> void:
	if (OS.has_feature("web")): return # Don't try to log on the web builds
	
	if (init_done == false):
		init()
	logfile.store_string(message + "\n")


func init() -> void:
	date = Time.get_datetime_string_from_system()
	var logfile_name = "LOG-" + date + ".txt"
	logfile_name = logfile_name.replace(":", "-")
	var logfile_path = log_dir + logfile_name
	logfile = FileAccess.open(logfile_path, FileAccess.WRITE)
	
	init_done = true
