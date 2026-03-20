# Unit testing using GUT

This project uses GUT(Godot Unit Testing) for unit testing with gdscript.

The full documentation can be found at: https://gut.readthedocs.io/en/v9.5.0 

## Prerequisities

- addons/gut in the repo

## Where to place tests

There are currently two different directories for where tests must be located. One is for the executioner in `res://executioner/tests` the other is for the editor in `res://editor/tests` You can also add subdirectories if needed and add tests under them.

## Creating tests

To create a new test file:

1. Create a new script under the chosen test directory
2. The file name must start with the prefix `test_` i.e. `test_example.gd`
3. THe file must extend the test script with `extends GutTest`

Now you can write tests using functions with the prefix `test_` i.e. `test_adding_unit():` You can also create classes for tests, which must also prefix `Test` i.e. `TestUnit` and must also extend GutTest.

Here are some commonly used assertions:

```bash
assert_eq(a, b) 
assert_ne(a, b)
assert_true(value)
assert_false(value)
assert_null(value)
assert_not_null(value)
```

The full list can be found at: https://gut.readthedocs.io/en/v9.5.0/class_ref/class_guttest.html#class-guttest 

There are also optional setup and teardown methods, which can be used in each script.

```bash
func before_each(): #Runs before each test

func after_each(): #Runs after each test

func before_all(): #Runs before all tests

func after_all(): #Runs after all tests
```

Example test:

```bash
extends GutTest

var value: int

# Runs before every test function
func before_each():
    value = 10

# Runs after every test function
func after_each():
    value = 0

func test_value_is_initialized():
    assert_eq(value, 10)

func test_value_can_be_modified():
    value += 5
    assert_eq(value, 15)
```

## Running tests

### Using the command line

Using an alias: `alias godot="Path/to/godot.exe"`

From the root of the project, in this case `grid-master-app` run

`godot --headless -s addons/gut/gut_cmdln.gd`

This runs all unit tests in `editor/tests` and `executioner/tests`

Optional flags can be found at: https://gut.readthedocs.io/en/v9.5.0/Command-Line.html 

### Using the GUT panel

1. First you must make sure that the gut plugin is enabled in the project settings to access the GUT panel. From the top left bar, choose `project -> project settings -> plugins` and enable gut. 
2. You should now see `GUT` in the bar at the bottom, which opens the GUT panel.
3. Configure the test directories in the GUT panel settings.
4. Now you can run all tests or individual test files and functions from the GUT panel

You can find the full guide with pictures in the Run Tests part at: https://gut.readthedocs.io/en/v9.5.0/Quick-Start.html 