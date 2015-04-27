
extends Node2D

# member variables here, example:
# var a=2
# var b="textvar"

var cardSide = null		# "blue" or "red"
var cardType = null		# "archer", "warrior"..
var currentCell = null	# Vector2
var beingSelected = false	# States if the current card is being selected (created)

func _ready():
	pass

func triggerSelection():
	beingSelected = !beingSelected
	if (beingSelected):
		get_node("Sprite").set_modulate(Color(1,1,1,0.5))
	else:
		get_node("Sprite").set_modulate(Color(1,1,1,1))

func setTexture(tex):
	get_node("Sprite").set_texture(tex)
	
func setCardType(newType, side):
	var grid = get_parent()
	cardType = newType
	cardSide = side
	get_node("Sprite").set_texture(grid.cardTextures[side + "_" + newType])