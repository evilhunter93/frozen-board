extends CharacterBody3D

@export var max_speed := 20
@export var acceleration := 2.0
@export var max_fall_speed := 30
@export var max_jump_velocity_y := 4.5
@export var max_jump_velocity_z := 2.0
@export var jump_charge_time := 1.0
@export var turn_speed := 1.0
@export var min_speed := 4.0

const SPEED = 5.0
var jump_charge := 0.0
const JUMP_VELOCITY = 4.5

func _physics_process(delta: float) -> void:
	global_transform = global_transform.interpolate_with(_align_with_surface(global_transform), 0.1)
	# Add the gravity and handle acceleration
	if not is_on_floor() :
		velocity += get_gravity() * delta
		
	if is_on_wall():
		_slide_velocity(delta)
	

	# Get the input direction and handle the movement.
	var steering := Input.get_axis("steer_left", "steer_right")
	rotate_y(steering * turn_speed * delta)

	# Handle jump.
	_jump(delta)

	move_and_slide()

func _slide_velocity(delta: float) -> void:
	# Find positive forward acceleration
	var forward_mult = Vector3.DOWN.dot(-global_basis.z.normalized())
	var forward_acc = forward_mult * 9.82
	
	# Define drag for deceleration
	var drag = 5
	var drag_mult = 1 if velocity.z > 0 else -1
	
	# Compute z velocity
	var velocity_dragless = velocity.z - forward_acc * delta
	if abs(velocity_dragless) < drag * delta:
		velocity = Vector3.ZERO
	else:
		velocity = Vector3(0, 0, forward_acc - drag * drag_mult)
	

	# Add a minimum down speed on walls
	var slope_direction = Vector3.DOWN.slide(get_wall_normal().normalized()).normalized()
	var slope_speed = velocity.dot(slope_direction)
	if slope_speed < min_speed:
		velocity += slope_direction * min_speed * delta

	# Cap speed
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed
	
func _jump(delta: float) -> void:
	if Input.is_action_pressed("charge_jump"):
		jump_charge = jump_charge + delta \
			if jump_charge < jump_charge_time \
			else jump_charge_time
	
	if Input.is_action_just_released("charge_jump"):
		if is_on_floor() or is_on_wall():
			velocity.y = max_jump_velocity_y * (jump_charge / jump_charge_time)
			if abs(velocity.z) < min_speed:
				velocity.z -= max_jump_velocity_z * (jump_charge / jump_charge_time)
		jump_charge = 0
	

func _align_with_surface(xform: Transform3D):
	var normal = Vector3.ZERO
	if is_on_floor():
		normal = get_floor_normal()
	elif is_on_wall():
		normal = get_wall_normal()
	else:
		normal = Vector3.UP

	xform.basis.y = normal
	xform.basis.x = xform.basis.z.cross(normal)
	xform.basis = xform.basis.orthonormalized()
	
	return xform
