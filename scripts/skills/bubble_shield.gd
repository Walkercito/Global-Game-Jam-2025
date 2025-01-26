extends BaseSkill

@export_group("Shield Properties")
@export var shield_duration: float = 4.0
@export var damage_reduction: float = 0.5  # 50% de reducción de daño
@export var slow_factor: float = 0.3  # 30% de ralentización
@export var shield_radius: float = 120.0

var shield_active: bool = false
var current_shield: Node2D = null
var affected_enemies: Dictionary = {}
var effect_area: Area2D
var collision_shape: CollisionShape2D

func _ready():
	super._ready()
	add_to_group("skills")
	
	# Cargar el icono de la habilidad
	skill_icon = preload("res://assets/sprites/skills/skills_bubble_shield.png")
	
	# Configurar valores base de la habilidad
	skill_name = "Escudo de Burbujas"
	description = "Crea un campo de burbujas que reduce el daño y ralentiza enemigos"
	skill_type = "defensive"
	cooldown = 10.0

func _execute_skill(caster_node: Node2D) -> void:
	if shield_active:
		return
	
	shield_active = true
	
	# Crear el escudo visual y su área de efecto
	current_shield = create_shield_effect(caster_node)
	
	# Activar partículas si existen
	if has_node("SkillParticles"):
		var particles = get_node("SkillParticles")
		particles.emitting = true
	
	# Configurar timer para la duración
	var timer = Timer.new()
	timer.wait_time = shield_duration
	timer.one_shot = true
	add_child(timer)
	timer.connect("timeout", _on_shield_expired)
	timer.start()
	
	# Crear y configurar área de efecto
	effect_area = Area2D.new()
	collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = shield_radius
	
	collision_shape.shape = circle_shape
	effect_area.add_child(collision_shape)
	current_shield.add_child(effect_area)
	
	# Configurar colisiones
	effect_area.collision_layer = 16  # Capa para efectos de habilidades
	effect_area.collision_mask = 64   # Capa para enemigos
	
	# Conectar señales
	effect_area.connect("body_entered", _on_body_entered)
	effect_area.connect("body_exited", _on_body_exited)

func create_shield_effect(caster: Node2D) -> Node2D:
	var shield = Node2D.new()
	
	# Añadir sprite visual del escudo
	var shield_sprite = Sprite2D.new()
	shield_sprite.texture = preload("res://assets/sprites/skills/skills_bubble_shield.png")
	shield_sprite.modulate = Color(0.5, 0.5, 1.0, 0.5) # Azul semi-transparente
	shield.add_child(shield_sprite)
	
	caster.add_child(shield)
	return shield

func _physics_process(_delta: float) -> void:
	if shield_active and current_shield and is_instance_valid(current_shield):
		current_shield.global_position = get_parent().global_position

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		affected_enemies[body] = true
		if body.has_method("apply_slow"):
			body.apply_slow(slow_factor)

func _on_body_exited(body: Node2D) -> void:
	if affected_enemies.has(body):
		affected_enemies.erase(body)
		if body.has_method("remove_slow"):
			body.remove_slow()

func _on_shield_expired() -> void:
	if current_shield and is_instance_valid(current_shield):
		# Desconectar señales
		if effect_area and is_instance_valid(effect_area):
			effect_area.disconnect("body_entered", _on_body_entered)
			effect_area.disconnect("body_exited", _on_body_exited)
		
		# Remover efectos de ralentización
		for enemy in affected_enemies.keys():
			if is_instance_valid(enemy) and enemy.has_method("remove_slow"):
				enemy.remove_slow()
		
		# Limpiar
		current_shield.queue_free()
		current_shield = null
		affected_enemies.clear()
		shield_active = false

func modify_incoming_damage(damage: float) -> float:
	if shield_active:
		return damage * (1.0 - damage_reduction)
	return damage 
