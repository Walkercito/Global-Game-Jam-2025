extends BaseSkill

@export_group("Cloud Properties")
@export var push_force: float = 300.0
@export var cloud_radius: float = 150.0
@export var cloud_duration: float = 2.0
@export var splash_damage: float = 5.0
@export var push_duration: float = 0.5

var cloud_active: bool = false
var active_cloud: Node2D = null
var affected_bodies: Dictionary = {}

func _ready():
    super._ready()
    add_to_group("skills")
    
    # Configurar valores base de la habilidad
    skill_name = "Nube de Espuma"
    description = "Crea una nube que empuja enemigos y cancela proyectiles"
    skill_type = "defensive"
    cooldown = 5.0
    
    # Configurar el área de efecto
    var area = get_node("EffectArea")
    area.collision_layer = %SkillManager.LAYERS.skill_effects
    area.collision_mask = (1 << (%SkillManager.LAYERS.enemy - 1)) | \
                         (1 << (%SkillManager.LAYERS.projectiles - 1))

func _execute_skill(caster_node: Node2D) -> void:
    if cloud_active:
        return
    
    cloud_active = true
    
    # Crear la nube visual
    active_cloud = create_cloud_effect(caster_node)
    
    # Configurar el área de efecto
    var area = get_node("EffectArea")
    var collision_shape = area.get_node("CollisionShape2D")
    var circle_shape = CircleShape2D.new()
    circle_shape.radius = cloud_radius
    collision_shape.shape = circle_shape
    
    # Activar partículas
    if skill_particles:
        skill_particles.emitting = true
    
    # Configurar timer para la duración
    var timer = get_node("CooldownTimer")
    timer.wait_time = cloud_duration
    timer.connect("timeout", _on_cloud_expired)
    timer.start()
    
    # Conectar señales
    area.connect("body_entered", _on_body_entered)
    area.connect("body_exited", _on_body_exited)
    area.connect("area_entered", _on_area_entered)

func create_cloud_effect(caster: Node2D) -> Node2D:
    var cloud = Node2D.new()
    # Aquí los sprites o efectos visuales de la nube
    caster.add_child(cloud)
    return cloud

func _physics_process(delta: float) -> void:
    if active_cloud:
        for body in affected_bodies.keys():
            if is_instance_valid(body):
                push_body(body, delta)

func push_body(body: Node2D, delta: float) -> void:
    if body.has_method("apply_force"):
        var direction = (body.global_position - active_cloud.global_position).normalized()
        var force = direction * push_force * delta
        body.apply_force(force)
        
        # Aplicar daño por salpicadura
        if body.has_method("take_damage"):
            body.take_damage(splash_damage * delta)

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("enemies") or body.is_in_group("pushable"):
        affected_bodies[body] = push_duration

func _on_body_exited(body: Node2D) -> void:
    if affected_bodies.has(body):
        affected_bodies.erase(body)

func _on_area_entered(area: Area2D) -> void:
    # Cancelar proyectiles
    if area.is_in_group("projectiles"):
        if area.has_method("cancel"):
            area.cancel()
        else:
            area.queue_free()

func _on_cloud_expired() -> void:
    if active_cloud:
        # Desconectar señales
        var area = get_node("EffectArea")
        area.disconnect("body_entered", _on_body_entered)
        area.disconnect("body_exited", _on_body_exited)
        area.disconnect("area_entered", _on_area_entered)
        
        # Limpiar
        active_cloud.queue_free()
        active_cloud = null
        affected_bodies.clear()
        cloud_active = false 