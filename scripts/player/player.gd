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

var is_dashing: bool = false
var dash_time: float = 0.0
var facing_right: bool = true
var can_air_dash: bool = true
var dash_direction: int = 1
var has_double_jump: bool = true
var current_speed = WALK_SPEED
var can_move: bool = true
var land_lock: bool = false  # Nueva variable para control de aterrizaje

@onready var animationController = $sprite

func _physics_process(delta):
	var was_on_floor = is_on_floor()
	
	current_speed = RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED
	
	# Actualizar animaciones después del movimiento
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
	
	var input = 0.0
	if can_move:
		input = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	
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
	
	# Manejar bloqueo de animación al aterrizar
	if not was_on_floor and is_on_floor():
		can_air_dash = true
		land_lock = true
		await get_tree().physics_frame  # Esperar un frame físico
		land_lock = false

func update_animations() -> void:
	animationController.flip_h = not facing_right

	if is_dashing:
		animationController.play("dash")
	elif not is_on_floor():
		if velocity.y < 0:
			animationController.play("jump")
		else:
			animationController.play("fall")
	else:
		if land_lock:  # Forzar animación de idle durante el aterrizaje
			animationController.play("idle")
		elif abs(velocity.x) > 10:
			animationController.play("run" if current_speed == RUN_SPEED else "walk")
		else:
			animationController.play("idle")
