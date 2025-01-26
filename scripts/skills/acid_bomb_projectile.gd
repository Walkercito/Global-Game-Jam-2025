extends Area2D

@export var SPEED: float = 300.0
@export var DAMAGE: float = 25.0
@export var EXPLOSION_RADIUS: float = 50.0

var direction: Vector2 = Vector2.RIGHT
var attached_to: Node2D = null

@onready var sprite = $AnimatedSprite2D
@onready var explosion_timer = $ExplosionTimer
@onready var particles = $CPUParticles2D

func _ready():
	# Conectar señales
	connect("body_entered", _on_body_entered)
	connect("area_entered", _on_area_entered)
	explosion_timer.connect("timeout", _on_explosion_timer_timeout)
	
	# Iniciar animación
	sprite.play("default")
	particles.emitting = false

func initialize(dir: Vector2) -> void:
	direction = dir.normalized()
	# Rotar el sprite en la dirección del movimiento
	sprite.rotation = direction.angle()

func _physics_process(delta: float) -> void:
	if not attached_to:
		# Mover la bomba mientras no esté pegada a nada
		position += direction * SPEED * delta
		
		# Opcional: Añadir un efecto de trail
		if particles:
			particles.emitting = true
			particles.direction = -direction
	else:
		# Si está pegada a un enemigo, seguir su posición
		if is_instance_valid(attached_to):
			global_position = attached_to.global_position
		else:
			attached_to = null

func _on_body_entered(body: Node2D) -> void:
	if not attached_to:
		if body.is_in_group("enemies"):
			# Pegarse al enemigo
			attached_to = body
			explosion_timer.start()
			particles.emitting = false
		elif body.is_in_group("world"):
			# Pegarse a la pared
			attached_to = self  # Se pega a sí misma
			explosion_timer.start()
			particles.emitting = false

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemyHurtBox") and not attached_to:
		var enemy = area.get_parent()
		if enemy and enemy.is_in_group("enemies"):
			attached_to = enemy
			explosion_timer.start()
			particles.emitting = false

func _on_explosion_timer_timeout() -> void:
	# Crear efecto de explosión
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 30
	particles.spread = 180.0
	
	# Detectar enemigos en el área de explosión
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = EXPLOSION_RADIUS
	query.shape = circle_shape
	query.collision_mask = 0b01000000  # Capa de enemigos
	query.transform = global_transform
	
	var results = space_state.intersect_shape(query)
	for result in results:
		if result.collider.has_method("take_damage"):
			result.collider.take_damage(DAMAGE)
	
	# Desactivar colisiones
	collision_layer = 0
	collision_mask = 0
	
	# Ocultar el sprite
	sprite.visible = false
	
	# Esperar a que terminen las partículas antes de destruir
	await get_tree().create_timer(1.0).timeout
	queue_free()
