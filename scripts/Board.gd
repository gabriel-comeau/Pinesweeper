extends Node2D

@onready var Tiles = $GameTiles
@onready var TopPanel = get_parent().find_child("TopPanel")

var TopPanelYOffset: int
var firstClick: bool = true
var activeGame: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	TopPanelYOffset = TopPanel.size.y
	setStartState()

func _enter_tree():
	if TopPanel != null:
		setStartState()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	
	if activeGame:
		
		if Globals.ActiveField.GameWon || Globals.ActiveField.GameLost:
			Globals.stopGameClock()
			activeGame = false
			if Globals.ActiveField.GameWon:
				TopPanel.showButtons()
				TopPanel.showVictoryText()
			elif Globals.ActiveField.GameLost:
				TopPanel.showButtons()
				TopPanel.showLossText()
		
	
		# Draw the current state of the board
		self.setTilemapFromField()
	
func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if isPositionInField(event.position):
				var fieldPos := self.getFieldPositionFromViewPortPosition(event.position)
				if event.button_index == 1:
					if firstClick:
						firstClick = false
						var needToSwitch := Globals.ActiveField.leftClick(fieldPos, true)
						if needToSwitch:
							# Switch to backup field
							Globals.ActiveField = Globals.FieldB
							Globals.startGameClock()
						else:
							# that click was good, can end this
							Globals.startGameClock()
							return
							
					# this will reclick the same square on the alternate field if a switch
					# happened or just do a normal click if this wasn't the first click
					Globals.ActiveField.leftClick(fieldPos)
							
					
				elif event.button_index == 2:
					Globals.ActiveField.rightClick(fieldPos)

# Set the board up (and its UI elements) to starting state
func setStartState():
	Globals.resetClock()
	Globals.RemainingMines = Globals.ActiveField.TotalMines
	TopPanel.hideMiddleControls()
	firstClick = true
	activeGame = true

# Check if the mouse event happened inside the board
func isPositionInField(pos: Vector2i) -> bool:
	# to the right of the game board
	if pos.x > Globals.ActiveField.Width * Globals.TILE_SIZE:
		return false
	
	# in top panel
	if pos.y < TopPanelYOffset:
		return false
	
	# under game board
	if pos.y > (Globals.ActiveField.Height * Globals.TILE_SIZE) + TopPanelYOffset:
		return false
	
	return true

# Get the vector tile position from the viewport mouse coordinate
func getFieldPositionFromViewPortPosition(vpPos: Vector2i) -> Vector2i:
	var x := (vpPos.x / Globals.TILE_SIZE)
	var y := ((vpPos.y - TopPanelYOffset) / Globals.TILE_SIZE)
	return Vector2i(x,y)

func setTilemapFromField():
	for y in range(Globals.ActiveField.Height):
		for x in range(Globals.ActiveField.Width):
			var atlasCoords := self.getTileAtlasCoordForState(Globals.ActiveField.BoardState[y][x])
			self.Tiles.set_cell(0, Vector2i(x,y), 0, atlasCoords, 0)

# Get the tile atlast coordinates to show the right tile for a given state
#
# TODO: is this really where this mapping should be maintained?
func getTileAtlasCoordForState(state: Field.States) -> Vector2i:
	if state == Field.States.UNCLICKED:
		return Vector2i(0,0)
	elif state == Field.States.ONE:
		return Vector2i(1,0)
	elif state == Field.States.TWO:
		return Vector2i(2,0)
	elif state == Field.States.THREE:
		return Vector2i(3,0)
	elif state == Field.States.FOUR:
		return Vector2i(4,0)
	elif state == Field.States.FIVE:
		return Vector2i(5,0)
	elif state == Field.States.SIX:
		return Vector2i(6,0)
	elif state == Field.States.SEVEN:
		return Vector2i(7,0)
	elif state == Field.States.EIGHT:
		return Vector2i(8,0)
	elif state == Field.States.QUESTION:
		return Vector2i(9,0)
	elif state == Field.States.MINE_FLAGGED:
		return Vector2i(10,0)
	elif state == Field.States.GAME_OVER_WRONG_MINE_FLAG:
		return Vector2i(11,0)
	elif state == Field.States.EMPTY:
		return Vector2i(12,0)
	elif state == Field.States.GAME_OVER_MINE_REVEAL:
		return Vector2i(13,0)
	elif state == Field.States.GAME_OVER_KILLED_BY:
		return Vector2i(14,0)
	else:
		return Vector2i(0,0)
