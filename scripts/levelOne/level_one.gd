extends Node2D

@onready var camera: Camera2D = $entity/player/camera
@onready var ui_layer: CanvasLayer = $CanvasLayer
@onready var entry: AnimatedSprite2D = $world/animatedSprites/entry/sprite2
@onready var entry_col: CollisionShape2D = $world/animatedSprites/entry/col/collison

var opend: bool = false


func _on_fov_body_entered(body: Node2D) -> void:
	if (body.name == "player"):
		create_tween().tween_property(camera, "zoom", Vector2(0.6, 0.6), 0.8)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		pass


func _on_fov_body_exited(body: Node2D) -> void:
	if (body.name == "player"):
		create_tween().tween_property(camera, "zoom", Vector2.ONE, 1.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		pass


func _on_openclose_body_entered(body: Node2D) -> void:
	if (body.name == 'player' and !opend):
		entry.play('open')
		opend = true
	else:
		pass


func _on_close_door_body_exited(body: Node2D) -> void:
	if (body.name == 'player'):
		entry.play('close')
		entry_col.position.y = 0.0
	else:
		pass
