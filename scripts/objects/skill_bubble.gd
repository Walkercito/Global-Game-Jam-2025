@tool
extends Node2D

signal skill_picked(skill_data: BaseSkill)

@export_enum("acid_bomb", "spy_bubble", "bubble_burst", "bubble_jump", "protective_bubble") var skill_type: String = "acid_bomb":
	set(value):
		skill_type = value
		if Engine.is_editor_hint():
			_load_skill()

var skill_data: BaseSkill
@onready var interaction_label = $Label
@onready var area = $Area2D
@onready var sprite = $AnimatedSprite2D

func _ready():
	if not Engine.is_editor_hint():
		area.connect("body_entered", _on_body_entered)
		area.connect("body_exited", _on_body_exited)
		_load_skill()

func _load_skill():
	var skill_script = load("res://scripts/skills/" + skill_type + ".gd")
	if skill_script:
		var skill: BaseSkill = skill_script.new()
		skill._ready() # Inicializar valores base
		set_skill(skill)

func set_skill(data: BaseSkill) -> void:
	skill_data = data
	# Configurar sprite según el tipo de habilidad
	if sprite:
		match skill_data.skill_type:
			"offensive":
				sprite.modulate = Color.RED
			"defensive":
				sprite.modulate = Color.BLUE
			"utility":
				sprite.modulate = Color.GREEN

func _input(event: InputEvent) -> void:
	if interaction_label.visible and event.is_action_pressed("pickup_skill"):
		emit_signal("skill_picked", skill_data)
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		interaction_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		interaction_label.visible = false

func get_skill_data() -> BaseSkill:
	return skill_data
