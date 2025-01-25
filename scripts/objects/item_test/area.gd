extends Area2D

@onready var text = $"../Label"

func _on_body_entered(body: Node2D) -> void:
	print("entrooo")
	text.visible = true


func _on_body_exited(body: Node2D) -> void:
	print("salioo")
	text.visible = false
