extends CharacterBody2D

const GRAVITY             = 2400.0
const MAX_SPEED           = 510.0
const MAX_FALL_SPEED      = 820.0
const ACCELERATION        = 9400.0
const JUMP_VELOCITY       = -680.0
const MIN_JUMP_VELOCITY   = -200.0

const COYOTE_TIME         = 0.11
const JUMP_BUFFER_TIME    = 0.10

var vel = Vector2()
var axis = Vector2()

var coyote_timer = 0.0
var jump_buffer_timer = 0.0

var can_jump = false
var airborne_friction = false
var sprite_color = "red"

func _physics_process(delta):
	if vel.y < 0:
		vel.y += GRAVITY * delta
	else:
		vel.y += GRAVITY * 1.8 * delta
		vel.y = min(vel.y, MAX_FALL_SPEED)

	airborne_friction = false
	get_input_axis()

	# Ground check / coyote logic
	if is_on_floor():
		can_jump = true
		coyote_timer = 0.0
		sprite_color = "red"
	else:
		coyote_timer += delta
		if coyote_timer > COYOTE_TIME:
			can_jump = false
		airborne_friction = true
		sprite_color = "blue"

	# Jump buffering
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME

	jump_buffer_timer -= delta

	if jump_buffer_timer > 0.0 and can_jump:
		jump()
		jump_buffer_timer = 0.0

	set_jump_height()
	horizontal_movement(delta)

	velocity = vel
	move_and_slide()
	vel = velocity

	apply_boxing_rotation()
	set_sprite_color()


func get_input_axis():
	axis = Vector2(
		float(Input.is_action_pressed("right")) - float(Input.is_action_pressed("left")),
		0.0
	)
	if axis != Vector2.ZERO:
		axis = axis.normalized()


func horizontal_movement(delta):
	if axis.x != 0:
		var target = axis.x * MAX_SPEED

		if sign(vel.x) != axis.x:
			vel.x = move_toward(vel.x, target, ACCELERATION * delta * 2.0)
		else:
			vel.x = move_toward(vel.x, target, ACCELERATION * delta)

		$Rotatable.scale.x = sign(axis.x)

	else:
		vel.x = move_toward(vel.x, 0, ACCELERATION * delta * 0.45)

	if airborne_friction:
		vel.x = lerp(vel.x, 0.0, 0.08)


func jump():
	vel.y = JUMP_VELOCITY
	can_jump = false


func set_jump_height():
	if Input.is_action_just_released("jump"):
		if vel.y < MIN_JUMP_VELOCITY:
			vel.y = MIN_JUMP_VELOCITY

func apply_boxing_rotation():
	var target_rot = 0.0

	if axis.x != 0 and abs(vel.x) > 0.01:
		target_rot = -deg_to_rad(5) * axis.x

	$Rotatable.rotation = lerp(
		$Rotatable.rotation,
		target_rot,
		0.7
	)

func set_sprite_color():
	match sprite_color:
		"red":
			$Rotatable/Sprite2D.modulate = Color(1, 0, 0)
		"blue":
			$Rotatable/Sprite2D.modulate = Color(0, 0, 1)
