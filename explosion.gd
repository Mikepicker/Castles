
extends Node2D

# member variables here, example:
# var a=2
# var b="textvar"
var explosion = null

func _ready():
	# Initialization here
	explosion = self.get_node("Particles2D")

