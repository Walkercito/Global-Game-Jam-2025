extends Area2D

@export var skill_data: Dictionary = {
	"name": "Default Skill",
	"description": "A skill pickup in the world",
	"icon": null,
	"type": "default"
}

var can_pickup = false
var player_ref = null

func _ready():
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		can_pickup = true
		player_ref = body

func _on_body_exited(body):
	if body.is_in_group("player"):
		can_pickup = false
		player_ref = null

func get_skill_data():
	return skill_data 
