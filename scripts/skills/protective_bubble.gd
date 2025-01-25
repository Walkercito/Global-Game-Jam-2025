extends BaseSkill

@export_group("Shield Properties")
@export var shield_duration: float = 3.0
@export var shield_health: int = 1
@export var explosion_radius: float = 100.0
@export var explosion_damage: float = 20.0

var shield_active: bool = false
var current_shield: Node2D

func _ready():
	super._ready()
	
	# Configurar valores base de la habilidad
	skill_name = "Burbuja Protectora"
	description = "Crea un escudo que explota al recibir daño"
	skill_type = "defensive"
	cooldown = 8.0

func _execute_skill(caster_node: Node2D) -> void:
	if shield_active:
		return
	
	shield_active = true
	
	# Crear el escudo visual
	current_shield = create_shield_effect(caster_node)
	
	# Configurar el timer para la duración
	var timer = get_node("CooldownTimer")
	timer.wait_time = shield_duration
	timer.connect("timeout", _on_shield_expired)
	timer.start()

func create_shield_effect(caster: Node2D) -> Node2D:
	# Implementar el efecto visual del escudo
	var shield = Node2D.new()
	# Añadir sprite, partículas, etc.
	caster.add_child(shield)
	return shield

func _on_shield_expired() -> void:
	# Cuando expire el escudo, lo destruimos sin causar explosión
	if current_shield:
		current_shield.queue_free()
		shield_active = false

func _on_shield_hit(_damage: float) -> void:
	shield_health -= 1
	if shield_health <= 0:
		explode()

func explode() -> void:
	if current_shield:
		# Crear explosión
		if skill_particles:
			skill_particles.emitting = true
		
		# Detectar y dañar enemigos en el área
		var area = get_node("EffectArea")
		var bodies = area.get_overlapping_bodies()
		for body in bodies:
			if body.has_method("take_damage"):
				body.take_damage(explosion_damage)
		
		# Limpiar
		current_shield.queue_free()
		shield_active = false 
