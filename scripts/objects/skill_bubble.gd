@tool
extends Node2D

signal skill_picked(skill_data: BaseSkill)

@export_enum("acid_bomb", "spy_bubble", "bubble_burst", "bubble_jump", "protective_bubble", "bubble_shield", "protective_bubble", "foam_cloud") var skill_type: String = "acid_bomb":
	set(value):
		skill_type = value
		if Engine.is_editor_hint():
			_load_skill()

var skill_data: BaseSkill
var player_in_range: bool = false
@onready var interaction_label = $Label
@onready var area = $Area2D
@onready var sprite = $AnimatedSprite2D

func _ready():
	if not Engine.is_editor_hint():
		area.connect("body_entered", _on_body_entered)
		area.connect("body_exited", _on_body_exited)
		add_to_group("skill_bubbles")
		_load_skill()
		print("Burbuja de habilidad creada: ", skill_type) # Debug

func _load_skill():
	var skill_script = load("res://scripts/skills/" + skill_type + ".gd")
	if skill_script:
		skill_data = skill_script.new()
		if skill_data:
			print("Habilidad cargada: ", skill_data.skill_name)
			# Configurar el color según el tipo
			if skill_data.skill_type == BaseSkill.SkillType.OFFENSIVE:
				sprite.modulate = Color(1, 0.5, 0.5, 1)
			elif skill_data.skill_type == BaseSkill.SkillType.DEFENSIVE:
				sprite.modulate = Color(0.5, 0.5, 1, 1)
			elif skill_data.skill_type == BaseSkill.SkillType.UTILITY:
				sprite.modulate = Color(0.5, 1, 0.5, 1)
		else:
			print("ERROR: No se pudo crear la instancia de la habilidad: ", skill_type)
	else:
		print("ERROR: No se pudo cargar el script de habilidad: ", skill_type)

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
	if player_in_range and event.is_action_pressed("pickup_skill"):
		emit_signal("skill_picked", skill_data)
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		interaction_label.visible = true
		print("Jugador puede recoger: ", skill_type) # Debug

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		interaction_label.visible = false

func get_skill_data() -> BaseSkill:
	return skill_data
