extends XRToolsPickable

var velocity:Vector3 = Vector3.ZERO
var ang_velocity:Vector3 = Vector3.ZERO

func let_go(by, p_linear_velocity,p_angular_velocity):
	super(by,p_linear_velocity,p_angular_velocity)
	
	freeze = true
	velocity = p_linear_velocity
	ang_velocity = p_angular_velocity

func _physics_process(delta: float) -> void:
	if is_picked_up():
		return
	
	var motion = velocity*delta
	var collision = move_and_collide(motion)
	
	if collision:
		velocity = velocity.bounce(collision.get_normal())
