class_name FieldGenerator extends Object

var RNG = RandomNumberGenerator.new()

func _init():
	self.RNG.randomize()

func Generate(width: int, height: int, mineCount: int, noMineVectors: Array) -> Field:
	var mines: Array[Vector2i] = []
	
	while mines.size() < mineCount:
		var exists := false
		var x := self.RNG.randi_range(0, width-1)
		var y := self.RNG.randi_range(0, height-1)
		
		# first, check if this mine already exists for this field
		for m in mines:
			if m.x == x && m.y == y:
				exists = true
				break
		
		if exists:
			continue
		
		# now check if this mine exists for noMineVectors arg (passed in from another field)
		for m in noMineVectors:
			if m.x == x && m.y == y:
				exists = true
				break
		
		if exists:
			continue
		
		# doesn't exist, add it
		mines.append(Vector2i(x,y))
				
	return Field.new(height, width, mineCount, mines)

