extends GutTest

var game_grid: GameGrid

# Initializes the GameGrid and fill it with debug tiles
func before_each():
	game_grid = GameGrid.new(10, 10)
	game_grid.debugFill()

func after_each():
	game_grid = null

# Test that the grid is filled with tiles
func test_grid_is_filled():
	for x in range(10):
		for y in range(10):
			assert_not_null(game_grid.getTile(x, y))

# Test that tiles are distinct instances
func test_tiles_are_distinct():
	var tile1 = game_grid.getTile(0, 0)
	var tile2 = game_grid.getTile(1,0)
	
	assert_ne(tile1, tile2, "The tiles should be different instances")

# Tests that fillTiles replaces old tiles
func test_fillTiles_replaces_old_tiles():
	var old_tile = game_grid.getTile(0,0)
	game_grid.debugFill()
	assert_ne(old_tile, game_grid.getTile(0,0), "The old tile should not equal the new tile")
