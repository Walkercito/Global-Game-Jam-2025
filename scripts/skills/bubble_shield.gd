extends BaseSkill

@export_group("Shield Properties")
@export var shield_duration: float = 4.0
@export var damage_reduction: float = 0.5  # 50% de reducción de daño
@export var slow_factor: float = 0.3  # 30% de ralentización
@export var shield_radius: float = 120.0

var shield_active: bool = false
var current_shield: Node2D = null
var affected_enemies: Dictionary = {}

func _ready():
    super._ready()
    add_to_group("skills")
    
    # Configurar valores base de la habilidad
    skill_name = "Escudo de Burbujas"
    description = "Crea un campo de burbujas que reduce el daño y ralentiza enemigos"
    skill_type = "defensive"
    cooldown = 10.0
    
    # Configurar el área de efecto
    var area = get_node("EffectArea")
    var collision_shape = area.get_node("CollisionShape2D")
    var circle_shape = CircleShape2D.new()
    circle_shape.radius = shield_radius
    collision_shape.shape = circle_shape

func _execute_skill(caster_node: Node2D) -> void:
    if shield_active:
        return
    
    shield_active = true
    
    # Crear el escudo visual
    current_shield = create_shield_effect(caster_node)
    
    # Activar partículas
    if skill_particles:
        skill_particles.emitting = true
    
    # Configurar timer para la duración
    var timer = get_node("CooldownTimer")
    timer.wait_time = shield_duration
    timer.connect("timeout", _on_shield_expired)
    timer.start()
    
    # Conectar señales
    var area = get_node("EffectArea")
    area.connect("body_entered", _on_body_entered)
    area.connect("body_exited", _on_body_exited)

func create_shield_effect(caster: Node2D) -> Node2D:
    var shield = Node2D.new()
    # Aquí añadiremos los sprites y efectos visuales del escudo
    caster.add_child(shield)
    return shield

func _physics_process(_delta: float) -> void:
    if shield_active and current_shield:
        # Mantener el escudo en la posición del jugador
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
    if current_shield:
        # Desconectar señales
        var area = get_node("EffectArea")
        area.disconnect("body_entered", _on_body_entered)
        area.disconnect("body_exited", _on_body_exited)
        
        # Remover efectos de ralentización
        for enemy in affected_enemies.keys():
            if is_instance_valid(enemy) and enemy.has_method("remove_slow"):
                enemy.remove_slow()
        
        # Limpiar
        current_shield.queue_free()
        current_shield = null
        affected_enemies.clear()
        shield_active = false

# Método para ser llamado cuando el jugador recibe daño
func modify_incoming_damage(damage: float) -> float:
    if shield_active:
        return damage * (1.0 - damage_reduction)
    return damage 