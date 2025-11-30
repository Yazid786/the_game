extends CharacterBody2D

const GRAVITY             = 2400.0
const MAX_SPEED           = 510.0
const MAX_FALL_SPEED      = 720.0
const ACCELERATION        = 9400.0
const JUMP_VELOCITY       = -680.0
const MIN_JUMP_VELOCITY   = -200.0

const COYOTE_TIME         = 0.11
const JUMP_BUFFER_TIME    = 0.10

const DASH_SPEED          = 900.0
const DASH_DURATION       = 0.18
const DASH_HOLD_MAX       = 0.45
const TIME_SLOW_SCALE     = 0.25


var player_vel = Vector2()
var axis = Vector2()

var coyote_timer = 0.0
var jump_buffer_timer = 0.0

var can_jump = false
var friction = false

var is_dashing = false
var dash_time = 0.0
var dash_hold_time = 0.0
var dash_direction = Vector2.ZERO
var dash_ready = false

var sprite_color = "red"

func _physics_process(delta: float):

	if player_vel.y < 0:
		player_vel.y += GRAVITY * delta
	elif player_vel.y >= 0:
		player_vel.y += GRAVITY * 1.8 * delta
		player_vel.y = min(player_vel.y, MAX_FALL_SPEED)
	
	
	friction = false
	get_input_axis()

	if is_on_floor():
		can_jump = true
		coyote_timer = 0.0
		sprite_color = "red"
	else:
		coyote_timer += delta
		if coyote_timer > COYOTE_TIME:
			can_jump = false
		friction = true
		sprite_color = "blue"

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME

	jump_buffer_timer -= delta
	if jump_buffer_timer > 0.0 and can_jump:
		jump()
		jump_buffer_timer = 0.0

	set_jump_height()
	horizontal_movement(delta)
	
	if Input.is_action_just_pressed("dash") and not is_dashing:
		Engine.time_scale = TIME_SLOW_SCALE
		dash_hold_time = 0.0
		dash_ready = true   # player is charging a dash

	if Input.is_action_pressed("dash") and dash_ready:
		dash_hold_time += delta
		if dash_hold_time > DASH_HOLD_MAX:
			# Cancel dash
			dash_ready = false
			Engine.time_scale = 1.0

	if Input.is_action_just_released("dash") and dash_ready:
		start_dash()

	velocity = player_vel
	move_and_slide()
	player_vel = velocity
	set_sprite_color()
	
	if is_dashing:
		dash_time -= delta
		player_vel = dash_direction * DASH_SPEED

		if dash_time <= 0.0:
			is_dashing = false

	
func start_dash():
	Engine.time_scale = 1.0
	is_dashing = true
	dash_time = DASH_DURATION

	if axis != Vector2.ZERO:
		dash_direction = axis.normalized()
	else:
		dash_direction = Vector2($Rotatable.scale.x, 0).normalized()

	player_vel = dash_direction * DASH_SPEED

	dash_ready = false


func horizontal_movement(delta: float):
	if axis.x != 0:
		player_vel.x = move_toward(player_vel.x, axis.x * MAX_SPEED, ACCELERATION * delta)
		$Rotatable.scale.x = sign(axis.x)
	else:
		player_vel.x = move_toward(player_vel.x, 0, ACCELERATION * delta * 0.4)
		
	if friction:
		player_vel.x = lerp(player_vel.x, 0.0, 0.001)

func jump():
	player_vel.y = JUMP_VELOCITY
	can_jump = false

func set_jump_height():
	if Input.is_action_just_released("jump"):
		if player_vel.y < MIN_JUMP_VELOCITY:
			player_vel.y = MIN_JUMP_VELOCITY

func get_input_axis():
	axis = Vector2(
		float(Input.is_action_pressed("right")) - float(Input.is_action_pressed("left")),
		float(Input.is_action_pressed("down"))  - float(Input.is_action_pressed("up"))
	)
	if axis != Vector2.ZERO:
		axis = axis.normalized()

func set_sprite_color():
	match sprite_color:
		"red":
			$Rotatable/Sprite2D.modulate = Color(1, 0, 0)
		"green":
			$Rotatable/Sprite2D.modulate = Color(0, 1, 0)
		"blue":
			$Rotatable/Sprite2D.modulate = Color(0, 0, 1)
