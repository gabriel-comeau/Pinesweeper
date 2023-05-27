extends Panel

@onready var RestartButton = $RestartButton
@onready var MainMenuButton = $MainMenuButton

# Called when the node enters the scene tree for the first time.
func _ready():
	hideMiddleControls()
	RestartButton.pressed.connect(resetBoard)
	MainMenuButton.pressed.connect(mainMenuPress)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Show timer
	var seconds := Globals.getElapsedSeconds()
	if seconds == 0:
		$Time.text = ""
	else:
		$Time.text = "%s" % seconds
	
	# Show mine counter
	var remaining := Globals.getRemainingMines()
	$MinesLeft.text = "%s" % remaining

# Hide all of the controls that only should appear when the game's ended
func hideMiddleControls():
	$GameStatusLabel.hide()
	$GameStatusLabel.text = ""
	$RestartButton.hide()
	$MainMenuButton.hide()

# Reveal the buttons when the game is over
func showButtons():
	$RestartButton.show()
	$MainMenuButton.show()

# Show the victory label
func showVictoryText():
	$GameStatusLabel.text = "You Win!"
	$GameStatusLabel.show()

# Show the defeat label
func showLossText():
	$GameStatusLabel.text = "You Lose!"
	$GameStatusLabel.show()

func mainMenuPress():
	get_tree().change_scene_to_file("res://mainmenu.tscn")

# Restart the game, generate two new fields and set the board back to starting state
func resetBoard():
	var generator := FieldGenerator.new()
	var currentWidth := Globals.ActiveField.Width
	var currentHeight := Globals.ActiveField.Height
	var currentTotal := Globals.ActiveField.TotalMines
	
	# Run the generator twice!
	var newFieldA = generator.Generate(currentWidth, currentHeight, currentTotal, [])
	var newFieldB = generator.Generate(currentWidth, currentHeight, currentTotal, newFieldA.Mines)
	
	Globals.FieldA = newFieldA
	Globals.FieldB = newFieldB
	Globals.ActiveField = Globals.FieldA
	
	var Board = get_parent().find_child("Board")
	Board.setStartState()
	
