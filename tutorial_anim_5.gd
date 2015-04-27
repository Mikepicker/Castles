
extends AnimationPlayer

# member variables here, example:
# var a=2
# var b="textvar"

func _ready():
	# Initialization here
	pass




func _on_Anim5_finished():
	get_parent().get_node("Anim6").play("Anim2")
