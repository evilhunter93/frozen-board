extends CharacterBody3D

@export var max_speed := 20
@export var max_fall_speed := 30
@export var max_jump_velocity_y := 10
@export var max_jump_velocity_z := 2.0
@export var jump_charge_time := 1.0
@export var turn_speed := 1.0
@export var min_speed := 4.0
@export var forward_drag := 0.1
@export var side_drag := 3.0

@onready var character_mesh: MeshInstance3D = $CharacterMesh

const SPEED = 5.0
var jump_charge := 0.0

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
		return
	
	if is_on_floor() or is_on_wall():
		var character_form = _align_with_surface(character_mesh.global_transform)
		character_mesh.global_transform = \
			character_mesh.global_transform.interpolate_with(character_form, 0.1)

	# Add the gravity and handle acceleration
	if not is_on_wall():
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

func _slide_velocity(delta: float) -> void:
	var wall_normal = get_wall_normal()

	var gravity_direction: Vector3 = get_gravity().normalized()
	var downhill_direction: Vector3 = gravity_direction.slide(wall_normal).normalized()
	# Calculate acceleration along the slope
	var slope_acceleration: Vector3 = downhill_direction * get_gravity().length()
	
	var z_direction: Vector3 = (-global_basis.z).normalized()
	var z_slope_direction: Vector3 = z_direction.slide(wall_normal).normalized()
	var z_acceleration: Vector3 = slope_acceleration.project(z_slope_direction)
	
	# Apply acceleration to velocity
	velocity += z_acceleration * delta
	print(velocity)
	
	# Apply forward drag
	_apply_drag(forward_drag, z_slope_direction, delta)
	print(velocity)
	
	# Apply side drag
	var x_direction: Vector3 = (global_basis.x).normalized()
	var x_slope_direction: Vector3 = x_direction.slide(wall_normal).normalized()
	_apply_drag(side_drag, x_slope_direction, delta)

	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

func _apply_drag(drag:float, dir: Vector3, delta: float):
	var deceleration = \
		drag * velocity.project(dir).normalized() * delta
	if abs(velocity.dot(dir)) > deceleration.length():
		velocity -= deceleration
	else:
		velocity -= velocity.project(dir)

func _jump(delta: float) -> void:
	if Input.is_action_pressed("charge_jump"):
		jump_charge = jump_charge + delta \
			if jump_charge < jump_charge_time \
			else jump_charge_time

	if Input.is_action_just_released("charge_jump"):
		if is_on_floor() or is_on_wall():		
			var z_direction: Vector3 = (-global_basis.z).normalized()
			if abs((velocity * z_direction).length()) < min_speed:
				velocity += max_jump_velocity_z * (z_direction) \
					* (jump_charge / jump_charge_time)

			velocity.y = max_jump_velocity_y * (jump_charge / jump_charge_time)
		jump_charge = 0
