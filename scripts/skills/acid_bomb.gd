extends BaseSkill

func _init():
	skill_name = "Bomba de Jabón Ácido"
	skill_description = "Se adhiere a enemigos y explota con daño en área"
	skill_type = SkillType.OFFENSIVE
	cooldown = 3.0
	
	# Cargar el icono de la habilidad
	var texture_path = "res://assets/sprites/skills/skills_soap.png"
	if ResourceLoader.exists(texture_path):
		skill_icon = load(texture_path)

func activate(player: CharacterBody2D) -> void:
	if not is_ready:
		return
		
	var bomb_scene = preload("res://scenes/skills/acid_bomb.tscn")
	var bomb = bomb_scene.instantiate() as Area2D
	
	# Posicionar la bomba delante del jugador
	var spawn_pos = player.global_position
	spawn_pos.x += 20 * (1 if player.facing_right else -1)
	bomb.global_position = spawn_pos
	
	# Configurar la dirección inicial
	if bomb.has_method("initialize"):  # Verificar que el método existe
		var direction = Vector2.RIGHT if player.facing_right else Vector2.LEFT
		bomb.initialize(direction)
	else:
		push_error("Error: El nodqo de la bomba no tiene el método initialize()")
	
	player.get_parent().add_child(bomb)
	start_cooldown()
