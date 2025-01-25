extends Node2D
class_name BaseSkill

@export_group("Skill Properties")
@export var skill_name: String = "Default Skill"
@export var description: String = "Skill description"
@export var icon: Texture2D
@export var skill_type: String = "default"
@export var cooldown: float = 1.0

@export_group("Visual Effects")
@export var skill_animation: AnimationPlayer
@export var skill_particles: GPUParticles2D

# Variables internas
var is_ready: bool = true
var current_cooldown: float = 0.0

func _ready():
	# Inicialización básica
	if skill_animation:
		skill_animation.connect("animation_finished", _on_animation_finished)

func _process(delta):
	if not is_ready:
		current_cooldown -= delta
		if current_cooldown <= 0:
			is_ready = true
			_on_cooldown_finished()

func activate(caster_node: Node2D) -> bool:
	if not is_ready:
		return false
	
	is_ready = false
	current_cooldown = cooldown
	_execute_skill(caster_node)
	return true

# Método virtual para ser sobrescrito por las habilidades específicas
func _execute_skill(_caster_node: Node2D) -> void:
	push_warning("Skill execution not implemented!")

func _on_animation_finished(_anim_name: String) -> void:
	pass

func _on_cooldown_finished() -> void:
	pass

func get_skill_data() -> Dictionary:
	return {
		"name": skill_name,
		"description": description,
		"icon": icon,
		"type": skill_type,
		"cooldown": cooldown
	} 
