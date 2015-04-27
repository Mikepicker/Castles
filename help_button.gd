
extends TextureButton

var pressed = false

func _ready():
	# Initialization here
	pass

func _on_HelpButton_pressed():
	pressed = true
	get_parent().get_node("AnimExit").play("MainMenuExit")


func _on_AnimExit_finished():
	if (pressed):
		get_node("/root/global").goto_scene("res://tutorial_scene.scn")
