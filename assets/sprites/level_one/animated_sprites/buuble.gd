extends Sprite2D

@onready var animation_tween: Tween
@onready var bubble: Sprite2D = $"."

func _ready():
	start_oscillation()

func start_oscillation():
	animation_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	animation_tween.tween_property(self, "position:y", -25.0, 1.0)
	animation_tween.tween_property(self, "position:y", -20.0, 1.0)


func _on_area_body_entered(body: Node2D) -> void:
	if body.name == "player":
		bubble.visible = true
	else:
		pass


func _on_area_body_exited(body: Node2D) -> void:
	if body.name == "player":
		bubble.visible = false
	else:
		pass
