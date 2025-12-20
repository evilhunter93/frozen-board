extends RigidBody3D

var steering := 0.0
var was_colliding := false
var velocity := 0.0

@onready var ray_cast_3d: RayCast3D = $RayCast3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	steering = Input.get_axis("steer_left", "steer_right")

func _physics_process(delta: float) -> void:
	rotate_y(steering * delta)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if ray_cast_3d.is_colliding():
		var surface_normal = ray_cast_3d.get_collision_normal().normalized()
		var slope_dir = state.linear_velocity.slide(surface_normal)
		
		if not was_colliding:
			velocity = slope_dir.normalized().dot(state.linear_velocity)
			was_colliding = true
		state.linear_velocity -= slope_dir
		state.linear_velocity.z = -velocity
		print(state.linear_velocity)
	else:
		was_colliding = false
