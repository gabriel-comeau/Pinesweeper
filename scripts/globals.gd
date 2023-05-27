extends Node

const GameModes = {
	0: {
		"name": "Easy",
		"height": 8,
		"width": 8,
		"mines": 10,
	},
	1: {
		"name": "Intermediate",
		"height": 16,
		"width": 16,
		"mines": 40,
	},
	2: {
		"name": "Expert",
		"height": 16,
		"width": 31,
		"mines": 99,
	},
}

const TILE_SIZE: int = 32

var FieldA: Field
var FieldB: Field
var ActiveField: Field

var StartTime = 0 #msecs
var EndTime = 0

var RemainingMines = 0

# Starts the game clock
func startGameClock():
	self.StartTime = Time.get_ticks_msec()

# Stops the game clock (when the game ends)
func stopGameClock():
	self.EndTime = Time.get_ticks_msec()

# Sets the clock times back to 0
func resetClock():
	self.StartTime = 0
	self.EndTime = 0

# Gets the current run of the clock
func getElapsedSeconds() -> int:
	if self.StartTime == 0:
		return 0
	if EndTime != 0:
		return ((EndTime - StartTime) / 1000) % 60
	else:
		return ((Time.get_ticks_msec() - StartTime) / 1000) % 60

# Gets the number of remaining mines on the board (for the UI)
func getRemainingMines() -> int:
	return RemainingMines
