class_name BaseSkill
extends Resource

enum SkillType {OFFENSIVE, DEFENSIVE, UTILITY}

@export var skill_name: String = ""
@export var skill_description: String = ""
@export var skill_icon: Texture2D
@export var skill_type: SkillType
@export var cooldown: float = 1.0
@export var duration: float = 0.0

var is_ready: bool = true
var current_cooldown: float = 0.0

func activate(player: CharacterBody2D) -> void:
	pass

func _process_cooldown(delta: float) -> void:
	if not is_ready:
		current_cooldown -= delta
		if current_cooldown <= 0:
			is_ready = true
			current_cooldown = 0.0

func start_cooldown() -> void:
	is_ready = false
	current_cooldown = cooldown
