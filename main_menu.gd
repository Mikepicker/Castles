
extends Control

# member variables here, example:
# var a=2
# var b="textvar"

func _ready():
	# Load Level
	var f = File.new()
	var err = f.open_encrypted_with_pass("user://level.bin",File.READ,OS.get_unique_ID())
	var level = f.get_var()
	if (level == null):
		level = 1
	f.close()
	if (level == 1):
		get_node("Title").set_text("1 CASTLE")
	else:
		get_node("Title").set_text(str(level) + " CASTLES")
	
	# Load high score
	f = File.new()
	err = f.open_encrypted_with_pass("user://highscore.bin",File.READ,OS.get_unique_ID())
	var hs = f.get_var()
	if (hs == null):
		hs = 0
	f.close()
	get_node("HighscoreLabel").set_text("Best " + str(hs))


