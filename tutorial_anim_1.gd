
extends AnimationPlayer

# member variables here, example:
# var a=2
# var b="textvar"

func _ready():
	# Initialization here
	pass




func _on_Anim1_finished():
	get_parent().get_node("Anim2").play("Anim2")
