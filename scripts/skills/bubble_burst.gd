extends BaseSkill

@export_group("Burst Properties")
@export var bubble_count: int = 8
@export var spread_angle: float = 45.0  # Ángulo del cono en grados
@export var bubble_speed: float = 300.0
@export var bubble_damage: float = 8.0
@export var push_force: float = 150.0
@export var charge_time: float = 1.0
@export var charge_damage_multiplier: float = 2.5

var is_charging: bool = false
var charge_start_time: float = 0.0
var charge_level: float = 0.0

func _ready():
    super._ready()
    add_to_group("skills")
    
    skill_name = "Ráfaga de Burbujas"
    description = "Lanza múltiples burbujas en cono. Mantén presionado para cargar"
    skill_type = "offensive"
    cooldown = 4.0

func _execute_skill(_caster_node: Node2D) -> void:
    is_charging = true
    charge_start_time = Time.get_ticks_msec() / 1000.0
    
    # Iniciar partículas de carga si existen
    if skill_particles:
        skill_particles.emitting = true

func _process(delta: float) -> void:
    super._process(delta)
    
    if is_charging:
        var current_time = Time.get_ticks_msec() / 1000.0
        charge_level = minf((current_time - charge_start_time) / charge_time, 1.0)
        
        # Verificar si se soltó el botón
        if Input.is_action_just_released("skill_1"):  # Ajustar según tu sistema de input
            release_burst(get_parent())
            is_charging = false

func release_burst(caster_node: Node2D) -> void:
    var damage_multiplier = 1.0 + (charge_level * (charge_damage_multiplier - 1.0))
    var actual_count = bubble_count + int(charge_level * bubble_count * 0.5)
    
    # Calcular dirección base hacia el cursor
    var mouse_pos = get_viewport().get_mouse_position()
    var base_direction = (mouse_pos - caster_node.global_position).normalized()
    
    # Crear burbujas en abanico
    for i in range(actual_count):
        var angle = deg_to_rad(spread_angle * 0.5)
        var fraction = float(i) / (actual_count - 1) - 0.5
        var bubble_rotation = base_direction.rotated(angle * 2 * fraction)
        
        create_bubble(caster_node.global_position, bubble_rotation, damage_multiplier)

func create_bubble(pos: Vector2, direction: Vector2, damage_multiplier: float) -> void:
    var bubble = Area2D.new()
    
    # Configurar colisionador
    var collision = CollisionShape2D.new()
    var circle = CircleShape2D.new()
    circle.radius = 8.0
    collision.shape = circle
    bubble.add_child(collision)
    
    # Configurar colisiones
    bubble.collision_layer = %SkillManager.LAYERS.skill_effects
    bubble.collision_mask = (1 << (%SkillManager.LAYERS.enemy - 1))
    
    # Añadir al árbol
    get_tree().current_scene.add_child(bubble)
    bubble.global_position = pos
    
    # Conectar señales
    bubble.connect("body_entered", _on_bubble_hit.bind(bubble, damage_multiplier))
    
    # Mover la burbuja
    var tween = create_tween()
    var target_pos = pos + direction * 200
    tween.tween_property(bubble, "global_position", target_pos, 0.8)
    tween.tween_callback(bubble.queue_free)

func _on_bubble_hit(body: Node2D, bubble: Area2D, damage_multiplier: float) -> void:
    if not body.is_in_group("enemies"):
        return
    
    # Aplicar daño
    if body.has_method("take_damage"):
        body.take_damage(bubble_damage * damage_multiplier)
    
    # Aplicar empuje
    if body.has_method("apply_force"):
        var direction = (body.global_position - bubble.global_position).normalized()
        var force = direction * push_force * damage_multiplier
        body.apply_force(force)
    
    # Destruir la burbuja al impactar
    bubble.queue_free() 