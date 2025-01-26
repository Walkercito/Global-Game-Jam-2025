extends Node2D

@onready var camera: Camera2D = $entity/player/camera
@onready var ui_layer: CanvasLayer = $CanvasLayer
@onready var entry: AnimatedSprite2D = $world/animatedSprites/entry/sprite2
@onready var entry_col: CollisionShape2D = $world/animatedSprites/entry/col/collison
@onready var player: CharacterBody2D = $entity/player
@onready var player_anim: AnimatedSprite2D = $entity/player/sprite

var opend: bool = false

func _ready() -> void:
	entry_col.disabled = true

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
		await entry.animation_finished
		entry_col.disabled = false
	else:
		pass


func _on_change_level_body_entered(body: Node2D) -> void:
	if (body.name == 'player'):
		player.set_physics_process(false)
		player.velocity = Vector2.ZERO

		player_anim.play("idle")
		await get_tree().create_timer(2.0).timeout

		get_tree().change_scene_to_file("res://scenes/levels/level_two.tscn")
	else:
		pass
