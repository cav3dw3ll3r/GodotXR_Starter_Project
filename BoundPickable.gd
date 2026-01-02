extends Node3D
class_name BoundPickable

@export var bound_pickable:PackedScene
@export var pickup_function:XRToolsFunctionPickup
@export var _grip_threshold = 0.5
@export var pickup_action:String = "grip"

var grip_pressed:bool = false
var spawned_instance:Node3D

@onready var controller = XRHelpers.get_xr_controller(self)

func _process(delta: float):
	var grip_value = controller.get_float(pickup_action)
	if (grip_pressed and grip_value < (_grip_threshold - 0.1)):
		grip_pressed = false
		call_deferred("_on_grip_released")
	elif (!grip_pressed and grip_value > (_grip_threshold + 0.1)):
		grip_pressed = true
		call_deferred("_on_grip_pressed")

func _on_grip_pressed():
	if pickup_function.picked_up_object:
		return
	
	if spawned_instance:
		spawned_instance.queue_free()
		await get_tree().process_frame
	
	spawned_instance = bound_pickable.instantiate()
	get_tree().root.add_child(spawned_instance)
	spawned_instance.global_position = global_position
	if(spawned_instance.has_method("pick_up")):
		pickup_function._pick_up_object(spawned_instance)
