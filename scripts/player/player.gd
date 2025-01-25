extends CharacterBody2D

@export var WALK_SPEED: float = 30.0
@export var RUN_SPEED: float = 150.0
@export var ACCELERATION: float = 800.0
@export var AIR_ACCELERATION: float = 800.0
@export var FRICTION: float = 2000.0
@export var JUMP: float = 450.0
@export var GRAVITY: float = 1600.0
@export var DASH_SPEED: float = 400.0
@export var DASH_DURATION: float = 0.15
@export var SCRATCH_DAMAGE: float = 15.0
@export var SCRATCH_COOLDOWN: float = 0.3

var is_dashing: bool = false
var dash_time: float = 0.0
var facing_right: bool = true
var can_air_dash: bool = true
var dash_direction: int = 1
var has_double_jump: bool = true
var current_speed = WALK_SPEED
var can_scratch: bool = true
var is_scratching: bool = false

@onready var animationController = $sprite
@onready var scratch_hitbox = $scratch_hitbox
@onready var scratch_cooldown = $scratch_cooldown

func _ready():
	# Configurar el timer de cooldown
	scratch_cooldown = Timer.new()
	scratch_cooldown.one_shot = true
	scratch_cooldown.wait_time = SCRATCH_COOLDOWN
	scratch_cooldown.connect("timeout", _on_scratch_cooldown_timeout)
	add_child(scratch_cooldown)
	
	# Conectar la señal de animación terminada
	animationController.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	var was_on_floor = is_on_floor()
	
	current_speed = RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED
	
	update_animations()
	
	if Input.is_action_just_pressed("dash") and (is_on_floor() or can_air_dash):
		is_dashing = true
		dash_time = DASH_DURATION
		velocity.y = 0
		
		if is_on_floor():
			dash_direction = 1 if facing_right else -1
		else:
			dash_direction = sign(velocity.x) if velocity.x != 0 else (1 if facing_right else -1)
			can_air_dash = false
	
	if is_dashing:
		dash_time -= delta
		velocity = Vector2(dash_direction * DASH_SPEED, 0)
		move_and_slide()
		if dash_time <= 0:
			is_dashing = false
			velocity.x = sign(velocity.x) * WALK_SPEED
		return
	
	var input = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	if input != 0:
		var accel = ACCELERATION if is_on_floor() else AIR_ACCELERATION
		velocity.x = move_toward(velocity.x, input * current_speed, accel * delta)
		facing_right = input > 0
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	
	if is_on_floor():
		has_double_jump = true
		if Input.is_action_just_pressed("jump"):
			velocity.y = -JUMP
	else:
		if Input.is_action_just_pressed("jump") and has_double_jump:
			velocity.y = -JUMP
			has_double_jump = false
	
	move_and_slide()
	
	if not was_on_floor and is_on_floor():
		can_air_dash = true

	# Manejar el arañazo
	if Input.is_action_just_pressed("attack") and can_scratch and not is_dashing:
		perform_scratch()

func perform_scratch() -> void:
	if not can_scratch or is_scratching:
		return
		
	is_scratching = true
	can_scratch = false
	scratch_cooldown.start()
	
	# Activar el área de daño y actualizar su posición según la dirección
	if scratch_hitbox:
		scratch_hitbox.position.x = abs(scratch_hitbox.position.x) * (1 if facing_right else -1)
		var bodies = scratch_hitbox.get_overlapping_bodies()
		
		for body in bodies:
			if body.is_in_group("enemies") and body.has_method("take_damage"):
				body.take_damage(SCRATCH_DAMAGE)
	
	# Reproducir la animación una sola vez
	animationController.stop()  # Detener cualquier animación actual
	animationController.play("scratch")

func _on_animation_finished() -> void:
	# Se llama cuando cualquier animación termina
	if animationController.animation == "scratch":
		is_scratching = false
		animationController.play("idle")  # Volver a la animación idle

func _on_scratch_cooldown_timeout() -> void:
	can_scratch = true

func update_animations() -> void:
	if is_scratching:
		return  # No cambiar la animación mientras está arañando
		
	animationController.flip_h = not facing_right
	
	if is_dashing:
		animationController.play("dash")
	elif not is_on_floor():
		if velocity.y < 0:
			animationController.play("jump")
		else:
			animationController.play("fall")
	else:
		if abs(velocity.x) > 10:
			animationController.play("run" if current_speed == RUN_SPEED else "walk")
		else:
			animationController.play("idle")
