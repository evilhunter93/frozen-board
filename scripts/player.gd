extends CharacterBody3D

@export var max_speed := 20
@export var max_fall_speed := 30
@export var max_jump_velocity_y := 10
@export var max_jump_velocity_z := 2.0
@export var jump_charge_time := 1.0
@export var turn_speed := 1.0
@export var min_speed := 4.0
@export var drag := 1.0
@export var side_drag := 3.0

@onready var character_mesh: MeshInstance3D = $CharacterMesh

const SPEED = 5.0
var jump_charge := 0.0
var was_in_air = true

func _physics_process(delta: float) -> void:
	if is_on_floor() or is_on_wall():
		var character_form = _align_with_surface(character_mesh.global_transform)
		character_mesh.global_transform = \
			character_mesh.global_transform.interpolate_with(character_form, 0.1)

	# Add the gravity and handle acceleration
	if not is_on_wall():
		was_in_air = true
		velocity += get_gravity() * delta
		if -velocity.y > max_fall_speed:
			velocity.y = -max_fall_speed
		
	if is_on_wall():
		_slide_velocity(delta)
	

	# Get the input direction and handle the movement.
	var steering := Input.get_axis("steer_right", "steer_left")
	rotate_y(steering * turn_speed * delta)

	# Handle jump.
	_jump(delta)
	
	move_and_slide()

func _slide_velocity(delta: float) -> void:
	var wall_normal = get_wall_normal()

	if was_in_air:
		was_in_air = false
		velocity = velocity.slide(wall_normal)

	var gravity_direction: Vector3 = get_gravity().normalized()
	var downhill_direction: Vector3 = gravity_direction.slide(wall_normal).normalized()
	# Calculate acceleration along the slope
	var slope_acceleration: Vector3 = downhill_direction * get_gravity().length()
	
	var z_direction: Vector3 = (-global_basis.z).normalized()
	var z_slope_direction: Vector3 = z_direction.slide(wall_normal).normalized()
	var z_acceleration: Vector3 = slope_acceleration.project(z_slope_direction)
	
	# Apply acceleration to velocity
	velocity += z_acceleration * delta
	
	# Apply forward drag
	var deceleration = \
		drag * velocity.project(z_slope_direction).normalized() * delta
	if velocity.dot(z_slope_direction) > deceleration.length():
		velocity -= deceleration
	else:
		velocity -= velocity.project(z_slope_direction)
	
	# Apply side drag
	var side_deceleration = \
		side_drag * velocity.project(downhill_direction).normalized() * delta
	if velocity.dot(downhill_direction) > side_deceleration.length():
		velocity -= side_deceleration
	else:
		velocity -= velocity.project(downhill_direction)

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
	else:
		normal = get_wall_normal()

	xform.basis.y = normal
	xform.basis.x = -xform.basis.z.cross(normal)
	xform.basis = xform.basis.orthonormalized()
	return xform
