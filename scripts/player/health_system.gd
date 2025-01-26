extends Node2D

signal health_changed(current_health: int)
signal player_died

@export var MAX_HEALTH: int = 3
var current_health: int

@onready var heart1_full = $Heart1/Full
@onready var heart2_full = $Heart2/Full
@onready var heart3_full = $Heart3/Full
@onready var heart1_empty = $Heart1/Empty
@onready var heart2_empty = $Heart2/Empty
@onready var heart3_empty = $Heart3/Empty

func _ready():
	current_health = MAX_HEALTH
	update_hearts_display()

func take_damage(amount: int = 1) -> void:
	current_health = max(0, current_health - amount)
	update_hearts_display()
	emit_signal("health_changed", current_health)
	
	if current_health <= 0:
		emit_signal("player_died")

func heal(amount: int = 1) -> void:
	current_health = min(MAX_HEALTH, current_health + amount)
	update_hearts_display()
	emit_signal("health_changed", current_health)

func update_hearts_display() -> void:
	heart1_full.visible = current_health >= 1
	heart1_empty.visible = current_health < 1
	
	heart2_full.visible = current_health >= 2
	heart2_empty.visible = current_health < 2
	
	heart3_full.visible = current_health >= 3
	heart3_empty.visible = current_health < 3
