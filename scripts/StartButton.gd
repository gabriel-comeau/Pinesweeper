extends Button

@onready var DifficultySelector := get_node("../DifficultySelector")
var Generator := FieldGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	self.pressed.connect(self.startGame)

func startGame():
	var gameMode = Globals.GameModes[getDifficultyIndex()]
	
	# Run the generator twice!
	Globals.FieldA = Generator.Generate(gameMode["width"], gameMode["height"], gameMode["mines"], [])
	Globals.FieldB = Generator.Generate(gameMode["width"], gameMode["height"], gameMode["mines"], Globals.FieldA.Mines)
	Globals.ActiveField = Globals.FieldA
	
	# transition to the main game scene
	get_tree().change_scene_to_file("res://game.tscn")
	
func getDifficultyIndex() -> int:
	return DifficultySelector.get_selected_id()
