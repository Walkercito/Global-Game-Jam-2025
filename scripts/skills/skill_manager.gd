extends Node

# Grupos predefinidos para las habilidades
const SKILL_GROUPS = {
	"enemies": "enemies",
	"pushable": "pushable",
	"projectiles": "projectiles",
	"skills": "skills"
}

# Capas de colisión
const LAYERS = {
	"player": 1,
	"player_hurt": 2,
	"world": 3,
	"items": 4,
	"skill_effects": 5,
	"enemy": 6,
	"enemy_hurt": 7,
	"projectiles": 8
}

# Tipos de habilidades disponibles
const SKILL_TYPES = {
	"offensive": "offensive",
	"defensive": "defensive",
	"utility": "utility"
}

func _ready():
	# Asegurarnos de que los grupos existan
	add_to_group("skill_manager")
	
	# Configurar máscaras de colisión para las habilidades
	setup_collision_masks()

func setup_collision_masks():
	# Configurar las máscaras de colisión para las áreas de efecto de las habilidades
	var skill_collision_mask = 0
	skill_collision_mask |= 1 << (LAYERS.enemy - 1)  # Detectar enemigos
	skill_collision_mask |= 1 << (LAYERS.projectiles - 1)  # Detectar proyectiles
	
	# Aplicar la máscara a todas las habilidades activas
	get_tree().call_group("skills", "set_collision_mask", skill_collision_mask)

func register_skill(skill_node: Node):
	if not skill_node.is_in_group("skills"):
		skill_node.add_to_group("skills")
	print("Habilidad registrada: ", skill_node.name) # Debug
	
	# Verificar que la habilidad tenga los datos necesarios
	if skill_node is BaseSkill:
		var skill_data = skill_node.get_skill_data()
		assert(skill_data.has_all(["name", "description", "icon", "type", "cooldown"]), 
			   "La habilidad debe tener todos los datos básicos configurados") 
