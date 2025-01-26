extends Control

# Estas señales serán conectadas desde el player
signal skill_activated(skill: BaseSkill)  # Cuando se activa una habilidad
signal skill_equipped(skill: BaseSkill)   # Cuando se equipa una habilidad
signal skill_dropped(skill: BaseSkill)    # Cuando se suelta una habilidad

var equipped_skills = [null, null]  # Solo las dos habilidades equipadas
var current_slot = 0  # Slot seleccionado actualmente (0 o 1)

@onready var skill_1_panel = $SkillsContainer/Skill1
@onready var skill_2_panel = $SkillsContainer/Skill2
@onready var skill_1_icon = $SkillsContainer/Skill1/Icon
@onready var skill_2_icon = $SkillsContainer/Skill2/Icon

func _ready():
	print("Sistema de habilidades inicializado") # Debug
	
	if not InputMap.has_action("pickup_skill"):
		InputMap.add_action("pickup_skill")
		var event = InputEventKey.new()
		event.keycode = KEY_F
		InputMap.action_add_event("pickup_skill", event)
	
	if not InputMap.has_action("drop_skill"):
		InputMap.add_action("drop_skill")
		var event = InputEventKey.new()
		event.keycode = KEY_R
		InputMap.action_add_event("drop_skill", event)
	
	if not InputMap.has_action("change_slot"):
		InputMap.add_action("change_slot")
		var event = InputEventKey.new()
		event.keycode = KEY_TAB
		InputMap.action_add_event("change_slot", event)
	
	# Inicializar UI
	_update_ui()

func _input(event):
	if event.is_action_pressed("pickup_skill"): # F
		_try_pickup_skill()
	elif event.is_action_pressed("drop_skill"): # R
		_drop_current_skill()
	elif event.is_action_pressed("change_slot"): # TAB
		_change_slot()
	elif event.is_action_pressed("skill_1"): # Q
		_activate_skill(0)
	elif event.is_action_pressed("skill_2"): # E
		_activate_skill(1)

func equip_skill(skill_data: BaseSkill, slot: int) -> bool:
	if not skill_data:
		print("ERROR: Intentando equipar una habilidad nula") # Debug
		return false
		
	if slot >= 0 and slot < equipped_skills.size():
		if equipped_skills[slot] != null:
			_drop_skill(slot)
		
		equipped_skills[slot] = skill_data
		_update_ui()
		print("Habilidad equipada en slot ", slot, ": ", skill_data.skill_name) # Debug
		emit_signal("skill_equipped", skill_data)
		return true
		
	print("ERROR: Slot inválido para equipar: ", slot) # Debug
	return false

func _drop_current_skill():
	_drop_skill(current_slot)

func _drop_skill(slot: int):
	if slot >= 0 and slot < equipped_skills.size():
		var skill_data = equipped_skills[slot]
		if skill_data != null:
			print("Soltando habilidad del slot ", slot, ": ", skill_data.skill_name) # Debug
			equipped_skills[slot] = null
			emit_signal("skill_dropped", skill_data)
			_update_ui()
		else:
			print("No hay habilidad para soltar en slot ", slot) # Debug

func _try_pickup_skill():
	var nearby_skills = get_tree().get_nodes_in_group("skill_bubbles")
	print("Buscando burbujas cercanas. Encontradas: ", nearby_skills.size()) # Debug
	
	for skill_bubble in nearby_skills:
		if skill_bubble.interaction_label.visible:
			var skill_data = skill_bubble.get_skill_data()
			if skill_data:
				print("Intentando equipar: ", skill_data.skill_name) # Debug
				if equip_skill(skill_data, current_slot):
					skill_bubble.queue_free()
					return
			else:
				print("ERROR: skill_data es null") # Debug

func _change_slot():
	current_slot = (current_slot + 1) % equipped_skills.size()
	print("Cambiado a slot ", current_slot) # Debug
	_update_ui()

func _activate_skill(slot: int):
	if slot >= 0 and slot < equipped_skills.size():
		if equipped_skills[slot] != null:
			print("Activando habilidad en slot ", slot, ": ", equipped_skills[slot].skill_name) # Debug
			emit_signal("skill_activated", equipped_skills[slot])
		else:
			print("No hay habilidad para activar en slot ", slot) # Debug

func _update_ui():
	# Actualizar visualización de slots
	skill_1_panel.modulate = Color(1, 1, 1, 1)
	skill_2_panel.modulate = Color(1, 1, 1, 1)
	
	# Actualizar iconos
	if equipped_skills[0]:
		skill_1_icon.texture = equipped_skills[0].skill_icon
		skill_1_icon.visible = true
	else:
		skill_1_icon.visible = false
		
	if equipped_skills[1]:
		skill_2_icon.texture = equipped_skills[1].skill_icon
		skill_2_icon.visible = true
	else:
		skill_2_icon.visible = false
	
	# Resaltar slot actual
	var current_panel = skill_1_panel if current_slot == 0 else skill_2_panel
	current_panel.modulate = Color(1.2, 1.2, 1.2, 1)
	
	print("UI actualizada - Slot actual: ", current_slot) # Debug
