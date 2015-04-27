
extends Control

# member variables here, example:
# var a=2
# var b="textvar"

func _ready():
	# Initialization here
	pass




func _on_Fade_finished():
	get_node("/root/global").goto_scene("res://main_menu.scn")
