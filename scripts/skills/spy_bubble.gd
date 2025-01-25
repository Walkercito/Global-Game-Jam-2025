extends BaseSkill

@export_group("Bubble Properties")
@export var projectile_speed: float = 350.0
@export var tracking_radius: float = 200.0
@export var lift_height: float = 150.0
@export var lift_duration: float = 2.0
@export var fall_damage: float = 25.0
@export var explosion_radius: float = 80.0
@export var pierce_count: int = 2

var active_bubbles: Array[Node2D] = []
var tracked_enemies: Dictionary = {}  # bubble: enemy

func _ready():
    super._ready()
    add_to_group("skills")
    
    skill_name = "Pompa Espía"
    description = "Lanza una burbuja que eleva y suelta enemigos"
    skill_type = "offensive"
    cooldown = 7.0

func _execute_skill(caster_node: Node2D) -> void:
    var bubble = create_bubble()
    get_tree().current_scene.add_child(bubble)
    bubble.global_position = caster_node.global_position
    
    # Dirección hacia el cursor
    var mouse_pos = get_viewport().get_mouse_position()
    var direction = (mouse_pos - bubble.global_position).normalized()
    
    bubble.linear_velocity = direction * projectile_speed
    active_bubbles.append(bubble)

func create_bubble() -> RigidBody2D:
    var bubble = RigidBody2D.new()
    bubble.gravity_scale = 0.0
    bubble.linear_damp = 1.0
    
    # Colisionador
    var collision = CollisionShape2D.new()
    var circle = CircleShape2D.new()
    circle.radius = 15.0
    collision.shape = circle
    bubble.add_child(collision)
    
    # Área de detección
    var detection_area = Area2D.new()
    var area_collision = CollisionShape2D.new()
    var detection_circle = CircleShape2D.new()
    detection_circle.radius = tracking_radius
    area_collision.shape = detection_circle
    detection_area.add_child(area_collision)
    bubble.add_child(detection_area)
    
    # Configurar colisiones
    detection_area.collision_layer = %SkillManager.LAYERS.skill_effects
    detection_area.collision_mask = (1 << (%SkillManager.LAYERS.enemy - 1))
    
    # Conectar señales
    detection_area.connect("body_entered", _on_enemy_detected.bind(bubble))
    
    return bubble

func _physics_process(_delta: float) -> void:
    for bubble in active_bubbles:
        if not is_instance_valid(bubble):
            continue
            
        if tracked_enemies.has(bubble):
            var enemy = tracked_enemies[bubble]
            if is_instance_valid(enemy):
                # Seguir al enemigo si está en fase de persecución
                var direction = (enemy.global_position - bubble.global_position).normalized()
                bubble.linear_velocity = direction * projectile_speed
            else:
                # El enemigo ya no existe
                _on_bubble_expired(bubble)

func _on_enemy_detected(body: Node2D, bubble: RigidBody2D) -> void:
    if not body.is_in_group("enemies") or tracked_enemies.has(bubble):
        return
    
    tracked_enemies[bubble] = body
    
    # Iniciar secuencia de elevación
    var tween = create_tween()
    var initial_pos = body.global_position
    var lift_pos = initial_pos + Vector2.UP * lift_height
    
    # Elevar
    tween.tween_property(body, "global_position", lift_pos, lift_duration * 0.5)
    # Mantener
    tween.tween_interval(lift_duration)
    # Soltar
    tween.tween_callback(_on_drop_enemy.bind(body, bubble))

func _on_drop_enemy(enemy: Node2D, bubble: RigidBody2D) -> void:
    if not is_instance_valid(enemy) or not is_instance_valid(bubble):
        return
    
    # Aplicar daño de caída
    if enemy.has_method("take_damage"):
        enemy.take_damage(fall_damage)
    
    # Crear explosión al caer
    create_fall_explosion(enemy.global_position)
    
    # Verificar si puede atravesar más enemigos
    pierce_count -= 1
    if pierce_count <= 0:
        _on_bubble_expired(bubble)
    else:
        tracked_enemies.erase(bubble)

func create_fall_explosion(pos: Vector2) -> void:
    # Efecto visual
    if skill_particles:
        var particles = skill_particles.duplicate()
        get_tree().current_scene.add_child(particles)
        particles.global_position = pos
        particles.emitting = true
    
    # Área de daño
    var explosion = Area2D.new()
    var collision = CollisionShape2D.new()
    var circle = CircleShape2D.new()
    circle.radius = explosion_radius
    collision.shape = circle
    explosion.add_child(collision)
    
    get_tree().current_scene.add_child(explosion)
    explosion.global_position = pos
    
    # Dañar enemigos cercanos
    var bodies = explosion.get_overlapping_bodies()
    for body in bodies:
        if body.has_method("take_damage"):
            var distance = body.global_position.distance_to(pos)
            var damage_factor = 1.0 - (distance / explosion_radius)
            body.take_damage(fall_damage * damage_factor)
    
    explosion.queue_free()

func _on_bubble_expired(bubble: RigidBody2D) -> void:
    if is_instance_valid(bubble):
        tracked_enemies.erase(bubble)
        active_bubbles.erase(bubble)
        bubble.queue_free() 