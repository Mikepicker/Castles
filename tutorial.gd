
extends Control

const TOTAL_ANIMS = 10
var currAnim = 1
var animPlaying = true

func _ready():
	set_process_input(true)
	
func _input(ev):
	if (animPlaying):
		return
		
	if (ev.type == InputEvent.MOUSE_BUTTON || ev.type == InputEvent.SCREEN_TOUCH):
		get_parent().get_node("TutorialAnims/Anim" + str(currAnim)).play("Anim" + str(currAnim))
		animPlaying = true
		
func _on_Anim1_finished():
	animPlaying = false
	currAnim += 1

func _on_Anim2_finished():
	animPlaying = false
	currAnim += 1

func _on_Anim3_finished():
	animPlaying = false
	currAnim += 1

func _on_Anim4_finished():
	animPlaying = false
	currAnim += 1

func _on_Anim5_finished():
	animPlaying = false
	currAnim += 1

func _on_Anim6_finished():
	animPlaying = false
	currAnim += 1
	
func _on_Anim7_finished():
	animPlaying = false
	currAnim += 1

func _on_Anim8_finished():
	animPlaying = false
	currAnim += 1

func _on_Anim9_finished():
	animPlaying = false
	currAnim += 1

func _on_Anim10_finished():
	animPlaying = false
	get_node("/root/global").goto_scene("res://main_menu.scn")