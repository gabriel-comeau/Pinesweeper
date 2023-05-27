class_name Field extends Node

enum States { 
	UNCLICKED,
	EMPTY,
	ONE,
	TWO,
	THREE,
	FOUR,
	FIVE,
	SIX,
	SEVEN,
	EIGHT,
	QUESTION,
	MINE_FLAGGED,
	GAME_OVER_MINE_REVEAL,
	GAME_OVER_KILLED_BY,
	GAME_OVER_WRONG_MINE_FLAG,
}

# Fixed info about the field
var Width: int
var Height: int
var TotalMines: int
var Mines: Array[Vector2i]

#  State - this is a 2d array that will mutate as the game goes on
var BoardState

var GameWon: bool
var GameLost: bool

var FlagCount: int

# Constructor
func _init(height: int, width: int, totalMines: int, mines: Array):
	self.Height = height
	self.Width = width
	self.TotalMines = totalMines
	self.Mines = mines
	self.FlagCount = 0
	self.BoardState = []
	self.GameWon = false
	self.GameLost = false
	
	Globals.RemainingMines = TotalMines
	
	# Set up initial state (nothing clicked on yet)
	for yPos in range(self.Height):
		self.BoardState.append([])
		for xPos in range(self.Width):
			self.BoardState[yPos].append(States.UNCLICKED)

# Handle actions where the player left-clicks on a cell
func leftClick(pos: Vector2i, firstClick: bool = false) -> bool:
	if self.GameLost || self.GameWon:
		return false
		
	if self.isGameWon():
		self.GameWon = true
		return false
	
	if self.BoardState[pos.y][pos.x] == States.UNCLICKED:
		
		if self.hasMineAtPosition(pos):
			if firstClick:
				return true
			self.BoardState[pos.y][pos.x] = States.GAME_OVER_KILLED_BY
			self.gameOver()
			return false
		else:
			var adjCount := self.getAdjacentMineCount(pos)
			if adjCount > 0:
				self.BoardState[pos.y][pos.x] = self.getNumberStateForCount(adjCount)
			else:
				self.BoardState[pos.y][pos.x] = States.EMPTY
				self.doFlood(pos, [])
	
	# Left clicking flagged squares will cycle the flags
	elif self.BoardState[pos.y][pos.x] == States.MINE_FLAGGED:
		self.BoardState[pos.y][pos.x] = States.QUESTION
		self.FlagCount -= 1
		Globals.RemainingMines = self.TotalMines - self.FlagCount
	
	elif self.BoardState[pos.y][pos.x] == States.QUESTION:
		self.BoardState[pos.y][pos.x] = States.UNCLICKED
	
	# Handle chording - we're gonna do it with left click instead
	# of worrying about double click detection
	if self.isPositionNumberState(pos):
		self.doChord(pos)
	
	if self.isGameWon():
		self.GameWon = true
	return false

# Handle actions where the player right clicks on a cell		
func rightClick(pos: Vector2i):
	if self.GameLost || self.GameWon:
		return
	
	if self.BoardState[pos.y][pos.x] == States.UNCLICKED:
		if self.FlagCount < self.TotalMines:
			self.BoardState[pos.y][pos.x] = States.MINE_FLAGGED
			self.FlagCount += 1
			Globals.RemainingMines = self.TotalMines - self.FlagCount
		
	elif self.BoardState[pos.y][pos.x] == States.MINE_FLAGGED:
		self.BoardState[pos.y][pos.x] = States.QUESTION
		self.FlagCount -= 1
		Globals.RemainingMines = self.TotalMines - self.FlagCount
	
	elif self.BoardState[pos.y][pos.x] == States.QUESTION:
		self.BoardState[pos.y][pos.x] = States.UNCLICKED
	
	if self.isGameWon():
		self.GameWon = true


# Chording is the process of automatically clicking all unclicked squares adjacent to a number square
# which is already in contact with its value of flagged squares.  So if the square has a 2 on it and
# it's directly adjacent to two flagged squares, this will effectively perform a click action on all
# the remaining unclicked adjacent squares.
func doChord(pos: Vector2i):
	var numValue := self.getCountForNumberState(self.BoardState[pos.y][pos.x])
	var touching := 0
	var unclicked := []
	
	# Now we have to see if the given position is touching ${numValue} of flagged squares
	# We'll also track all of the adjacent UNCLICKED ones, since we'll use those if we have
	# indeed hit the count.
	var adjPositions := self.getValidSurroundingPositions(pos)
	for aPos in adjPositions:
		if self.BoardState[aPos.y][aPos.x] == States.MINE_FLAGGED:
			touching += 1
		elif self.BoardState[aPos.y][aPos.x] == States.UNCLICKED:
			unclicked.append(aPos)

	# OK - now we can see if we have enough to do the chord
	if touching == numValue:
		for toClick in unclicked:
			self.leftClick(toClick)
	
# Flooding unlocks all of the empty squares adjacent to a revealed empty square
# This process continues until every touching empty square from that first one is cleared
#
# This function is recursive so if this game ever implements REALLY big maps this could become
# a problem.
#
# Another note: we are definitely going to be rechecking grid squares multiple times with this method
# but it keeps the algo as simple as possible so probably worth it
func doFlood(pos: Vector2i, checked: Array[Vector2i]):
	var surroundingPositions := self.getValidSurroundingPositions(pos)
	for sPos in surroundingPositions:
		if checked.has(sPos):
			continue
		checked.append(sPos)
		if self.hasMineAtPosition(sPos):
			continue
		var surCount := self.getAdjacentMineCount(sPos)
		if surCount > 0:
			self.BoardState[sPos.y][sPos.x] = self.getNumberStateForCount(surCount)
		else:
			self.BoardState[sPos.y][sPos.x] = States.EMPTY
			doFlood(sPos, checked)

# Check if the game's been won or not
func isGameWon() -> bool:
	# check for any unclicked squares or wrongly flagged mines
	for yPos in range(self.Height):
		for xPos in range(self.Width):
			if self.BoardState[yPos][xPos] == States.UNCLICKED:
				return false
			elif self.BoardState[yPos][xPos] == States.MINE_FLAGGED:
				if !self.hasMineAtPosition(Vector2i(xPos, yPos)):
					return false
	
	return true

# Oops a mine was clicked.  Set the board to gameover status - reveal all the
# mines and wrong guesses.
func gameOver():
	self.GameLost = true
	for yPos in range(Height):
		for xPos in range(Width):
			if self.BoardState[yPos][xPos] == States.UNCLICKED || self.BoardState[yPos][xPos] == States.QUESTION:
				if self.hasMineAtPosition(Vector2i(xPos, yPos)):
					self.BoardState[yPos][xPos] = States.GAME_OVER_MINE_REVEAL
			elif self.BoardState[yPos][xPos] == States.MINE_FLAGGED:
				if !self.hasMineAtPosition(Vector2i(xPos, yPos)):
					self.BoardState[yPos][xPos] = States.GAME_OVER_WRONG_MINE_FLAG

# Get the matching state for a given adjacent mine count
func getNumberStateForCount(count: int) -> States:
	if count == 1:
		return States.ONE
	elif count == 2:
		return States.TWO
	elif count == 3:
		return States.THREE
	elif count == 4:
		return States.FOUR
	elif count == 5:
		return States.FIVE
	elif count == 6:
		return States.SIX
	elif count == 7:
		return States.SEVEN
	elif count == 8:
		return States.EIGHT
	else:
		return States.EMPTY

# Get the adjacent mine count as an int, from a given state
func getCountForNumberState(state: States) -> int:
	if state == States.ONE:
		return 1
	elif state == States.TWO:
		return 2
	elif state == States.THREE:
		return 3
	elif state == States.FOUR:
		return 4
	elif state == States.FIVE:
		return 5
	elif state == States.SIX:
		return 6
	elif state == States.SEVEN:
		return 7
	elif state == States.EIGHT:
		return 8
	else:
		return 0

# Checks if a given position is one of the eight number states
func isPositionNumberState(pos: Vector2) -> bool:
	if self.BoardState[pos.y][pos.x] == States.ONE:
		return true
	elif self.BoardState[pos.y][pos.x] == States.TWO:
		return true
	elif self.BoardState[pos.y][pos.x] == States.THREE:
		return true
	elif self.BoardState[pos.y][pos.x] == States.FOUR:
		return true
	elif self.BoardState[pos.y][pos.x] == States.FIVE:
		return true
	elif self.BoardState[pos.y][pos.x] == States.SIX:
		return true
	elif self.BoardState[pos.y][pos.x] == States.SEVEN:
		return true
	elif self.BoardState[pos.y][pos.x] == States.EIGHT:
		return true
	
	return false

# Get all the surrounding vectors for a given position
#
# NOTE: this does not ensure validity - if the original position is at the
# edge of the board it will generate some that are out of bounds
func getSurroundingPositions(pos: Vector2i) -> Array[Vector2i]:
	return [
		Vector2i(pos.x + 1, pos.y - 1),
		Vector2i(pos.x + 1, pos.y),
		Vector2i(pos.x + 1, pos.y + 1),
		Vector2i(pos.x, pos.y + 1),
		Vector2i(pos.x - 1, pos.y + 1),
		Vector2i(pos.x - 1, pos.y),
		Vector2i(pos.x - 1, pos.y - 1),
		Vector2i(pos.x, pos.y - 1)
	]

# Get all the *valid* surrounding positions from the original position
func getValidSurroundingPositions(pos: Vector2i) -> Array[Vector2i]:
	var valid: Array[Vector2i] = []
	var all := self.getSurroundingPositions(pos)
	for aPos in all:
		if self.isValidPosition(aPos):
			valid.append(aPos)
	return valid
	
	
# Check if a given position is valid on the field
func isValidPosition(pos: Vector2i) -> bool:
	if pos.x < 0 || pos.x >= self.Width:
		return false
	if pos.y < 0 || pos.y >= self.Height:
		return false
	return true

# Check if a given position has a mine
func hasMineAtPosition(pos: Vector2i) -> bool:
	for m in self.Mines:
		if m.x == pos.x && m.y == pos.y:
			return true
	
	return false

# Check all the squares around the given position to see if they've got mines
func getAdjacentMineCount(pos: Vector2i) -> int:
	var count := 0
	var adjPositions := self.getValidSurroundingPositions(pos)
	for aPos in adjPositions:
		if self.hasMineAtPosition(aPos):
			count += 1

	return count
