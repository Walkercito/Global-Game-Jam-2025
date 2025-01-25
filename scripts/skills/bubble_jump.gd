extends BaseSkill

@export_group("Jump Properties")
@export var base_distance: float = 200.0
@export var max_charge_distance: float = 400.0
@export var charge_time: float = 0.8
@export var explosion_radius: float = 80.0
@export var explosion_damage: float = 20.0
@export var teleport_speed: float = 0.15  # Duración de la animación de teleport

var is_charging: bool = false
var charge_start_time: float = 0.0
var charge_level: float = 0.0
var teleport_preview: Node2D

func _ready():
    super._ready()
    add_to_group("skills")
    
    skill_name = "Salto de Burbuja"
    description = "Teletransporte rápido. Mantén presionado para mayor distancia y explosión"
    skill_type = "utility"
    cooldown = 5.0
    
    # Crear preview del teleport
    create_teleport_preview()

func create_teleport_preview() -> void:
    teleport_preview = Node2D.new()
    var preview_sprite = Sprite2D.new()
    # Configurar sprite del preview (ajustar según tus assets)
    teleport_preview.add_child(preview_sprite)
    teleport_preview.visible = false
    add_child(teleport_preview)

func _execute_skill(_caster_node: Node2D) -> void:
    is_charging = true
    charge_start_time = Time.get_ticks_msec() / 1000.0
    teleport_preview.visible = true
    
    # Iniciar partículas de carga
    if skill_particles:
        skill_particles.emitting = true

func _process(delta: float) -> void:
    super._process(delta)
    
    if is_charging:
        var current_time = Time.get_ticks_msec() / 1000.0
        charge_level = minf((current_time - charge_start_time) / charge_time, 1.0)
        
        # Actualizar preview
        update_teleport_preview()
        
        # Verificar si se soltó el botón
        if Input.is_action_just_released("skill_1"):  # Ajustar según tu sistema de input
            perform_teleport(get_parent())
            is_charging = false
            teleport_preview.visible = false

func update_teleport_preview() -> void:
    var mouse_pos = get_viewport().get_mouse_position()
    var start_pos = get_parent().global_position
    var direction = (mouse_pos - start_pos).normalized()
    var distance = lerp(base_distance, max_charge_distance, charge_level)
    var target_pos = start_pos + direction * distance
    
    # Limitar por colisiones con el mundo
    var space_state = get_world_2d().direct_space_state
    var query = PhysicsRayQueryParameters2D.create(start_pos, target_pos)
    query.collision_mask = (1 << (%SkillManager.LAYERS.world - 1))
    var result = space_state.intersect_ray(query)
    
    if result:
        target_pos = result.position - direction * 10.0  # Pequeño offset para no quedar dentro de la pared
    
    teleport_preview.global_position = target_pos

func perform_teleport(caster_node: Node2D) -> void:
    var start_pos = caster_node.global_position
    var target_pos = teleport_preview.global_position
    
    # Efecto visual de inicio
    if skill_particles:
        var start_particles = skill_particles.duplicate()
        get_tree().current_scene.add_child(start_particles)
        start_particles.global_position = start_pos
        start_particles.emitting = true
        
        # Autodestrucción de partículas
        var timer = Timer.new()
        start_particles.add_child(timer)
        timer.connect("timeout", func(): start_particles.queue_free())
        timer.start(2.0)
    
    # Animación de teleport
    var tween = create_tween()
    tween.tween_property(caster_node, "global_position", target_pos, teleport_speed)
    tween.tween_callback(func(): _on_teleport_complete(target_pos))

func _on_teleport_complete(pos: Vector2) -> void:
    # Efecto visual de llegada
    if skill_particles:
        var end_particles = skill_particles.duplicate()
        get_tree().current_scene.add_child(end_particles)
        end_particles.global_position = pos
        end_particles.emitting = true
        
        # Autodestrucción de partículas
        var timer = Timer.new()
        end_particles.add_child(timer)
        timer.connect("timeout", func(): end_particles.queue_free())
        timer.start(2.0)
    
    # Crear explosión si está cargado
    if charge_level > 0.5:  # Solo explota si está cargado más del 50%
        create_explosion(pos)

func create_explosion(pos: Vector2) -> void:
    var explosion_area = Area2D.new()
    var collision = CollisionShape2D.new()
    var circle = CircleShape2D.new()
    circle.radius = explosion_radius
    collision.shape = circle
    explosion_area.add_child(collision)
    
    # Configurar colisiones
    explosion_area.collision_layer = %SkillManager.LAYERS.skill_effects
    explosion_area.collision_mask = (1 << (%SkillManager.LAYERS.enemy - 1))
    
    # Añadir al árbol
    get_tree().current_scene.add_child(explosion_area)
    explosion_area.global_position = pos
    
    # Dañar enemigos en el área
    var bodies = explosion_area.get_overlapping_bodies()
    for body in bodies:
        if body.has_method("take_damage"):
            var distance = body.global_position.distance_to(pos)
            var damage_factor = 1.0 - (distance / explosion_radius)
            var final_damage = explosion_damage * damage_factor * charge_level
            body.take_damage(final_damage)
    
    # Limpiar
    explosion_area.queue_free() 