extends Control

signal skill_activated(skill_index: int)
signal try_pickup_skill(slot: int)
signal skill_dropped(skill_data, slot: int)

var equipped_skills = [null, null]  # Solo las dos habilidades equipadas
var current_slot = 0  # Slot seleccionado actualmente (0 o 1)

func _ready():
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
		emit_signal("try_pickup_skill", current_slot)
	elif event.is_action_pressed("drop_skill"): # R
		_drop_current_skill()
	elif event.is_action_pressed("change_slot"): # TAB
		_change_slot()
	elif event.is_action_pressed("skill_1"): # Q
		_activate_skill(0)
	elif event.is_action_pressed("skill_2"): # E
		_activate_skill(1)

func equip_skill(skill_data, slot: int):
	if slot >= 0 and slot < equipped_skills.size():
		# Si ya hay una habilidad en el slot, la soltamos en el mundo
		if equipped_skills[slot] != null:
			_drop_skill(slot)
		
		# Equipamos la nueva habilidad
		equipped_skills[slot] = skill_data
		_update_ui()
		return true
	return false

func _drop_current_skill():
	_drop_skill(current_slot)

func _drop_skill(slot: int):
	if equipped_skills[slot] != null:
		# Emitir señal para crear la habilidad en el mundo
		emit_signal("skill_dropped", equipped_skills[slot], slot)
		equipped_skills[slot] = null
		_update_ui()

func _activate_skill(index: int):
	if equipped_skills[index] != null:
		emit_signal("skill_activated", index)

func _change_slot():
	current_slot = (current_slot + 1) % equipped_skills.size()
	_update_ui()

func _update_ui():
	# Actualizar la interfaz visual
	for i in range(equipped_skills.size()):
		var skill_panel = get_node("SkillsContainer/Skill" + str(i + 1))
		var skill = equipped_skills[i]
		
		# Actualizar el visual del panel
		if skill != null:
			if skill_panel.has_node("Icon"):
				skill_panel.get_node("Icon").texture = skill.icon
		else:
			# Resetear el panel a su estado vacío
			if skill_panel.has_node("Icon"):
				skill_panel.get_node("Icon").texture = null
		
		# Resaltar el slot seleccionado
		skill_panel.modulate = Color(1.5, 1.5, 1.5) if i == current_slot else Color(1, 1, 1)
