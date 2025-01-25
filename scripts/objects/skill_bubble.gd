extends Node2D

var skill_data: Resource
@onready var interaction_label = $Label
@onready var area = $Area2D
@onready var sprite = $AnimatedSprite2D

func _ready():
    area.connect("body_entered", _on_body_entered)
    area.connect("body_exited", _on_body_exited)

func set_skill(data: Resource):
    skill_data = data
    # Configurar sprite según el tipo de habilidad
    match skill_data.skill_type:
        "offensive":
            # Configurar animación ofensiva
            pass
        "defensive":
            # Configurar animación defensiva
            pass
        "utility":
            # Configurar animación de utilidad
            pass

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        interaction_label.visible = true

func _on_body_exited(body: Node2D) -> void:
    if body.is_in_group("player"):
        interaction_label.visible = false

func get_skill_data() -> Resource:
    return skill_data 