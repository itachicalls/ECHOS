extends Node3D

## Low-poly trainer character — jacket, cap, backpack silhouette.


func _ready() -> void:
	_build()


func _build() -> void:
	for c in get_children():
		c.queue_free()

	var skin := LowPolyKit.mat(Color("f4a261"))
	var jacket := LowPolyKit.mat(Color("457b9d"))
	var pants := LowPolyKit.mat(Color("264653"))
	var cap := LowPolyKit.mat(Color("e76f51"))
	var pack := LowPolyKit.mat(Color("2a9d8f"))
	var shoe := LowPolyKit.mat(Color("1d3557"))

	_add_box(Vector3(0.42, 0.55, 0.28), jacket, Vector3(0, 0.95, 0))
	_add_box(Vector3(0.36, 0.22, 0.24), pants, Vector3(0, 0.55, 0))
	_add_box(Vector3(0.3, 0.3, 0.3), skin, Vector3(0, 1.38, 0))
	_add_box(Vector3(0.34, 0.12, 0.34), cap, Vector3(0, 1.62, 0.02))
	_add_box(Vector3(0.42, 0.14, 0.05), LowPolyKit.mat(Color("e76f51").darkened(0.1)), Vector3(0, 1.58, 0.2))
	_add_box(Vector3(0.22, 0.28, 0.14), pack, Vector3(0, 1.0, -0.2))
	_add_box(Vector3(0.14, 0.42, 0.14), LowPolyKit.mat(Color("457b9d").darkened(0.12)), Vector3(-0.3, 0.95, 0), Vector3(0, 0, 18))
	_add_box(Vector3(0.14, 0.42, 0.14), LowPolyKit.mat(Color("457b9d").darkened(0.12)), Vector3(0.3, 0.95, 0), Vector3(0, 0, -18))
	_add_box(Vector3(0.16, 0.38, 0.2), pants, Vector3(-0.12, 0.2, 0.04))
	_add_box(Vector3(0.16, 0.38, 0.2), pants, Vector3(0.12, 0.2, 0.04))
	_add_box(Vector3(0.18, 0.1, 0.26), shoe, Vector3(-0.12, 0.05, 0.06))
	_add_box(Vector3(0.18, 0.1, 0.26), shoe, Vector3(0.12, 0.05, 0.06))
	# Eyes
	LowPolyKit.sphere(0.04, Color("1d3557"), Vector3(-0.08, 1.4, 0.14), self, 4)
	LowPolyKit.sphere(0.04, Color("1d3557"), Vector3(0.08, 1.4, 0.14), self, 4)


func _add_box(size: Vector3, material: StandardMaterial3D, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> void:
	var b := BoxMesh.new()
	b.size = size
	var m := MeshInstance3D.new()
	m.mesh = b
	m.material_override = material
	m.position = pos
	m.rotation_degrees = rot
	add_child(m)
