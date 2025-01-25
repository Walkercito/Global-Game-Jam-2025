extends CharacterBody2D

@export var SPEED: float = 100.0
@export var ACCELERATION: float = 800.0
@export var AIR_ACCELERATION: float = 800.0
@export var FRICTION: float = 2000.0
@export var JUMP: float = 350.0
@export var GRAVITY: float = 1600.0
@export var DASH_SPEED: float = 400.0
@export var DASH_DURATION: float = 0.15

var is_dashing = false
var dash_time = 0.0
var facing_right = true
var can_air_dash = true
var dash_direction = 1
var has_double_jump = true  # Control del doble salto

@onready var sprite = $AnimatedSprite2D

func _physics_process(delta):
	var was_on_floor = is_on_floor()
	
	# Manejo de animaciones
	update_animations()
	
	if Input.is_action_just_pressed("dash") and (is_on_floor() or can_air_dash):
		is_dashing = true
		dash_time = DASH_DURATION
		velocity.y = 0  # Cancelar gravedad al iniciar dash
		
		# Determinar dirección del dash
		if is_on_floor():
			dash_direction = 1 if facing_right else -1
		else:
			dash_direction = sign(velocity.x) if velocity.x != 0 else (1 if facing_right else -1)
			can_air_dash = false
	

	if is_dashing:
		dash_time -= delta
		velocity = Vector2(dash_direction * DASH_SPEED, 0)  # Movimiento horizontal sin gravedad
		move_and_slide()
		if dash_time <= 0:
			is_dashing = false
			velocity.x = sign(velocity.x) * SPEED
		return
	

	var input = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	if input != 0:
		var accel = ACCELERATION if is_on_floor() else AIR_ACCELERATION
		velocity.x = move_toward(velocity.x, input * SPEED, accel * delta)
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
			velocity.y = -JUMP * 0.5
			has_double_jump = false
	
	move_and_slide()
	

	if not was_on_floor and is_on_floor():
		can_air_dash = true

func update_animations():
	# Voltear el sprite según la dirección
	sprite.flip_h = not facing_right
	
	# Activar animación según el estado
	if abs(velocity.x) > 0 and is_on_floor():
		sprite.play("walk")
	else:
		if sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")
		else:
			sprite.stop()  
