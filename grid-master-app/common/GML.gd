extends Node
## GML, which stands for Game Master Logger

# this isn't very good and we should probably just use the built in
# godot logging tools

# Constants controlling where to log
enum LoggerBackend {STDOUT, LOGFILE, HYBRID}
const LOGGER: LoggerBackend = LoggerBackend.STDOUT

# Loglevels in most verbose order to least verbose order.
# Note: most likely the most of these aren't needed.
enum LogLevel {TRACE, DEBUG, INFO, WARN, ERROR, FATAL}
const LogLevelPrefix: Dictionary[LogLevel, String] = {
	LogLevel.TRACE: "TRACE",
	LogLevel.DEBUG: "DEBUG",
	LogLevel.INFO: "INFO",
	LogLevel.WARN: "WARNING",
	LogLevel.ERROR: "ERROR",
	LogLevel.FATAL: "FATAL"
}
const LOGLEVEL: LogLevel = LogLevel.DEBUG

const log_dir = "res://logs/"
static var logfile : FileAccess
static var _initialized : bool = false

static func log(message : String, level: LogLevel = LogLevel.DEBUG) -> void:
	var log_message: String = "[ %s ] (%s) %s" % [LogLevelPrefix[level], _get_timestamp_string(), message]

	# On web builds, ignore the logger backend and use standard output/error
	# that will show up on the console output.
	if OS.has_feature("web") or LOGGER == LoggerBackend.STDOUT or LOGGER == LoggerBackend.HYBRID:
		if level == LogLevel.ERROR or level == LogLevel.FATAL:
			printerr(log_message)
		else:
			print(log_message)

	if (LOGGER == LoggerBackend.LOGFILE or LOGGER == LoggerBackend.HYBRID) \
			and !OS.has_feature("web"):
		if _initialized == false:
			_initialize()
		logfile.store_string(log_message + "\n")

# Note: This will return a string that has the following format:
#		
static func _get_timestamp_string() -> String:
	return Time.get_datetime_string_from_system(false, true).replace(":", "-")

static func _initialize() -> void:
	var logfile_name = "LOG-%s.txt" % _get_timestamp_string().replace(" ", "-")
	
	logfile_name = logfile_name.replace(":", "-").replace(" ", "-")
	var logfile_path = log_dir + logfile_name
	logfile = FileAccess.open(logfile_path, FileAccess.WRITE)
	
	_initialized = true
