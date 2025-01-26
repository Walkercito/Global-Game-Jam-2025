extends Node2D


func _on_play_button_down() -> void:
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/levels/level_one.tscn")
