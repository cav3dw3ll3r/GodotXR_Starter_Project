@tool
extends EditorScript

var cube_tile = preload("res://Prefabs/Block.tscn")
var cube_size = 1.0
var map_size:int = 6

const cubes = 20
const spacing = 1.5

func _run() -> void:
	print("This is my swag editor script 67")
	var root = get_editor_interface().get_edited_scene_root()
	var parent = root.get_node("Environment/Flooring")
	for child in parent.get_children():
		child.queue_free()
	var xPos = 0
	var yPos = 0
	var zPos = 0
	var cube_size = 6
	var spawned = 0
	while spawned < cubes:
		var rand = randf()
		if rand > 0.5:
			xPos+=spacing
		else:
			xPos-=spacing
		rand = randf()
		if rand > 0.5:
			yPos+=spacing
		else:
			yPos-=spacing
		rand = randf()
		if rand > 0.5:
			zPos += spacing
		else:
			zPos -= spacing
		rand = randf()
		if rand > 0.5:
			spawn_single_cube(root,parent,Vector3(xPos,yPos,zPos),Vector3.ZERO)
			spawned+=1
func spawn_single_cube(root, parent, position, rotation):
	var cube_instance = cube_tile.instantiate()
	parent.add_child(cube_instance)
	cube_instance.owner=root
	cube_instance.position = position
	cube_instance.rotation = rotation
	pass
