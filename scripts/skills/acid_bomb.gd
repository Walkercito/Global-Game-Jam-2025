extends BaseSkill

@export_group("Bomb Properties")
@export var stick_duration: float = 3.0
@export var explosion_radius: float = 100.0
@export var initial_damage: float = 15.0
@export var explosion_damage: float = 30.0
@export var acid_pool_duration: float = 4.0
@export var acid_damage_per_second: float = 10.0
@export var projectile_speed: float = 400.0

var active_bombs: Array[Node2D] = []
var acid_pools: Array[Node2D] = []

func _ready():
	super._ready()
	add_to_group("skills")
	
	skill_icon = preload("res://assets/sprites/skills/skills_soap.png")
	
	# Configurar valores base de la habilidad
	skill_name = "Bomba de Jabón Ácido"
	description = "Lanza una bomba que se adhiere y explota, dejando un charco ácido"
	skill_type = "offensive"
	cooldown = 6.0

func _execute_skill(caster_node: Node2D) -> void:
	# Crear y lanzar la bomba
	var bomb = create_bomb()
	get_tree().current_scene.add_child(bomb)
	bomb.global_position = caster_node.global_position
	
	# Calcular dirección hacia el cursor
	var mouse_pos = get_viewport().get_mouse_position()
	var direction = (mouse_pos - bomb.global_position).normalized()
	
	# Aplicar velocidad inicial
	bomb.linear_velocity = direction * projectile_speed
	active_bombs.append(bomb)

func create_bomb() -> RigidBody2D:
	var bomb = RigidBody2D.new()
	
	# Configurar física
	bomb.gravity_scale = 0.5
	bomb.linear_damp = 1.0
	
	# Añadir colisionador
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 10.0
	collision.shape = circle
	bomb.add_child(collision)
	
	# Añadir área de detección
	var area = Area2D.new()
	var area_collision = CollisionShape2D.new()
	area_collision.shape = circle
	area.add_child(area_collision)
	bomb.add_child(area)
	
	# Configurar colisiones
	area.collision_layer = %SkillManager.LAYERS.skill_effects
	area.collision_mask = (1 << (%SkillManager.LAYERS.enemy - 1))
	
	# Conectar señales
	area.connect("body_entered", _on_bomb_hit.bind(bomb))
	
	# Timer para explosión automática
	var timer = Timer.new()
	timer.wait_time = stick_duration
	timer.one_shot = true
	timer.connect("timeout", _on_bomb_explode.bind(bomb))
	bomb.add_child(timer)
	timer.start()
	
	return bomb

func _on_bomb_hit(body: Node2D, bomb: RigidBody2D) -> void:
	if body.is_in_group("enemies"):
		# Adherir la bomba al enemigo
		var remote = RemoteTransform2D.new()
		body.add_child(remote)
		remote.remote_path = bomb.get_path()
		
		# Aplicar daño inicial
		if body.has_method("take_damage"):
			body.take_damage(initial_damage)

func _on_bomb_explode(bomb: RigidBody2D) -> void:
	if not is_instance_valid(bomb):
		return
	
	# Crear explosión
	if skill_particles:
		var particles = skill_particles.duplicate()
		get_tree().current_scene.add_child(particles)
		particles.global_position = bomb.global_position
		particles.emitting = true
	
	# Detectar enemigos en el área
	var explosion_area = Area2D.new()
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = explosion_radius
	collision.shape = circle
	explosion_area.add_child(collision)
	get_tree().current_scene.add_child(explosion_area)
	explosion_area.global_position = bomb.global_position
	
	# Dañar enemigos en el área
	var bodies = explosion_area.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("take_damage"):
			body.take_damage(explosion_damage)
	
	# Crear charco de ácido
	create_acid_pool(bomb.global_position)
	
	# Limpiar
	explosion_area.queue_free()
	active_bombs.erase(bomb)
	bomb.queue_free()

func create_acid_pool(pos: Vector2) -> void:
	var pool = Area2D.new()
	
	# Configurar colisionador
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = explosion_radius * 0.7  # Charco más pequeño que la explosión
	collision.shape = circle
	pool.add_child(collision)
	
	# Configurar colisiones
	pool.collision_layer = %SkillManager.LAYERS.skill_effects
	pool.collision_mask = (1 << (%SkillManager.LAYERS.enemy - 1))
	
	# Timer para duración del charco
	var timer = Timer.new()
	timer.wait_time = acid_pool_duration
	timer.one_shot = true
	timer.connect("timeout", _on_pool_expired.bind(pool))
	pool.add_child(timer)
	
	# Añadir al árbol y lista
	get_tree().current_scene.add_child(pool)
	pool.global_position = pos
	acid_pools.append(pool)
	timer.start()
	
	# Iniciar el daño por segundo
	var damage_timer = Timer.new()
	damage_timer.wait_time = 1.0  # Daño cada segundo
	pool.add_child(damage_timer)
	damage_timer.connect("timeout", _on_pool_damage.bind(pool))
	damage_timer.start()

func _on_pool_damage(pool: Area2D) -> void:
	if not is_instance_valid(pool):
		return
	
	var bodies = pool.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("take_damage"):
			body.take_damage(acid_damage_per_second)

func _on_pool_expired(pool: Area2D) -> void:
	if is_instance_valid(pool):
		acid_pools.erase(pool)
		pool.queue_free()
