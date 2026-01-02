extends Node3D

@onready var mesh = $MeshInstance3D
@onready var material = mesh.get_active_material(0)

var unique_material

var on_color:Color = Color.CHARTREUSE
var off_color:Color = Color.INDIGO

var is_on = false

func _ready() -> void:
	unique_material = material.duplicate()
	unique_material.albedo_color=off_color
	mesh.set_surface_override_material(0,unique_material)
	

func toggle_color():
	is_on = !is_on
	if is_on:
		unique_material.albedo_color = on_color
	else:
		unique_material.albedo_color = off_color

func on_hit(node):
	if node is RigidBody3D:
		toggle_color()
	pass
