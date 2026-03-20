## This is a post run hook that makes sure that when no tests were run
## GUT will exit with a failing exit code.

extends "res://addons/gut/hook_script.gd"

var EXIT_CODE_ERROR = 1
var EXIT_CODE_SUCCESS = 0

func run():
	print("[ HOOK ] Validating test run totals.")
	
	var summary = gut.get_summary()
	var totals = summary.get_totals()

	# If no test were run, ignore the zero failing count
	# and indicate failing test run with the exit code.
	if totals.tests == 0:
		printerr("[ HOOK ] No tests were run.")
		set_exit_code(EXIT_CODE_ERROR)
		return

	if totals.warnings != 0:
		print("[ HOOK ] Some of the tests resulted in warnings (treating warnings as error).")
		set_exit_code(EXIT_CODE_ERROR)
	elif totals.failing == 0:
		print("[ HOOK ] All tests ran successfully.")
		set_exit_code(EXIT_CODE_SUCCESS)
	else:
		printerr("[ HOOK ] Some tests failed.")
		set_exit_code(EXIT_CODE_ERROR)
