class_name LowPolyKit
extends RefCounted

## Shared low-poly material + mesh helpers for Echoheart's stylized world.


static func mat(color: Color, shade: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color * shade
	m.roughness = 0.92
	m.metallic = 0.0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


static func add_mesh(mesh: Mesh, material: StandardMaterial3D, pos: Vector3, parent: Node3D, rot: Vector3 = Vector3.ZERO, scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = material
	inst.position = pos
	inst.rotation_degrees = rot
	inst.scale = scale
	parent.add_child(inst)
	return inst


static func box(size: Vector3, color: Color, pos: Vector3, parent: Node3D, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return add_mesh(b, mat(color), pos, parent, rot)


static func sphere(radius: float, color: Color, pos: Vector3, parent: Node3D, segments: int = 8) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = segments
	s.rings = maxi(4, segments / 2)
	return add_mesh(s, mat(color), pos, parent)


static func cylinder(bottom: float, top: float, height: float, color: Color, pos: Vector3, parent: Node3D, segments: int = 6) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.bottom_radius = bottom
	c.top_radius = top
	c.height = height
	c.radial_segments = segments
	return add_mesh(c, mat(color), pos, parent)


static func cone(radius: float, height: float, color: Color, pos: Vector3, parent: Node3D, segments: int = 6) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.bottom_radius = radius
	c.top_radius = 0.01
	c.height = height
	c.radial_segments = segments
	return add_mesh(c, mat(color), pos, parent)


static func prism(width: float, height: float, depth: float, color: Color, pos: Vector3, parent: Node3D) -> MeshInstance3D:
	# Low-poly roof / tent shape using a thin box tilted — readable and cheap.
	return box(Vector3(width, height * 0.35, depth), color, pos + Vector3(0, height * 0.5, 0), parent, Vector3(0, 0, 0))


static func ground_plane(size: Vector2, color: Color, parent: Node3D, y: float = 0.0) -> StaticBody3D:
	var body := StaticBody3D.new()
	var mesh_inst := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(size.x, 0.35, size.y)
	mesh_inst.mesh = plane
	mesh_inst.material_override = mat(color)
	mesh_inst.position = Vector3(0, -0.15, 0)
	body.add_child(mesh_inst)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x, 0.35, size.y)
	col.shape = shape
	col.position = Vector3(0, -0.15, 0)
	body.add_child(col)
	body.position.y = y
	parent.add_child(body)
	return body


static func grass_tuft(pos: Vector3, parent: Node3D, tall: bool = false) -> void:
	var h := 0.55 if tall else 0.35
	var greens := [Color("52b788"), Color("40916c"), Color("74c69d")]
	for i in 3:
		var angle := deg_to_rad(i * 120.0 + randf_range(-10, 10))
		box(Vector3(0.08, h, 0.22), greens[i % greens.size()], pos + Vector3(sin(angle) * 0.08, h * 0.5, cos(angle) * 0.08), parent, Vector3(0, angle * 57.3, 12))


static func pine_tree(pos: Vector3, parent: Node3D, scale: float = 1.0) -> void:
	var root := Node3D.new()
	root.position = pos
	root.scale = Vector3.ONE * scale
	parent.add_child(root)
	cylinder(0.12 * scale, 0.16 * scale, 1.1 * scale, Color("6f4e37"), Vector3(0, 0.55 * scale, 0), root, 5)
	cone(0.75 * scale, 1.0 * scale, Color("2d6a4f"), Vector3(0, 1.35 * scale, 0), root, 6)
	cone(0.55 * scale, 0.8 * scale, Color("40916c"), Vector3(0, 1.95 * scale, 0), root, 6)
	cone(0.35 * scale, 0.65 * scale, Color("52b788"), Vector3(0, 2.45 * scale, 0), root, 5)


static func round_tree(pos: Vector3, parent: Node3D) -> void:
	cylinder(0.14, 0.14, 1.0, Color("6f4e37"), pos + Vector3(0, 0.5, 0), parent, 5)
	sphere(0.85, Color("2a9d8f"), pos + Vector3(0, 1.55, 0), parent, 8)


static func fence_line(start: Vector3, end: Vector3, parent: Node3D) -> void:
	var dir := end - start
	var steps := int(dir.length() / 1.6)
	for i in steps + 1:
		var t := float(i) / float(maxi(1, steps))
		var p := start.lerp(end, t)
		box(Vector3(0.12, 0.7, 0.12), Color("d4a373"), p + Vector3(0, 0.35, 0), parent)
	if steps > 0:
		var rail_a := start.lerp(end, 0.0) + Vector3(0, 0.55, 0)
		var rail_b := start.lerp(end, 1.0) + Vector3(0, 0.55, 0)
		box(Vector3(dir.length(), 0.06, 0.06), Color("bc6c25"), (rail_a + rail_b) * 0.5, parent)


static func path_tile(pos: Vector3, parent: Node3D, size: float = 1.3) -> void:
	box(Vector3(size, 0.06, size * 0.9), Color("d4a373"), pos + Vector3(0, 0.03, 0), parent)
	box(Vector3(size * 0.85, 0.04, size * 0.75), Color("e9c46a").darkened(0.15), pos + Vector3(0, 0.07, 0), parent)


static func sign_post(pos: Vector3, label: String, parent: Node3D, color: Color = Color("fefae0")) -> void:
	box(Vector3(0.14, 1.2, 0.14), Color("6f4e37"), pos + Vector3(0, 0.6, 0), parent)
	box(Vector3(1.4, 0.55, 0.08), color, pos + Vector3(0, 1.35, 0), parent)
	# Label as 3D isn't trivial without font mesh — caller uses toast on interact.


static func cottage(pos: Vector3, parent: Node3D, wall: Color, roof: Color, door: Color = Color("264653")) -> void:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	box(Vector3(3.6, 2.4, 3.2), wall, Vector3(0, 1.2, 0), root)
	box(Vector3(0.9, 1.5, 0.12), door, Vector3(0, 0.75, 1.62), root)
	box(Vector3(0.55, 0.55, 0.12), Color("a8dadc"), Vector3(-1.0, 1.35, 1.62), root)
	box(Vector3(0.55, 0.55, 0.12), Color("a8dadc"), Vector3(1.0, 1.35, 1.62), root)
	# Roof — two sloped boxes
	box(Vector3(4.0, 0.25, 2.0), roof, Vector3(0, 2.65, -0.55), root, Vector3(-28, 0, 0))
	box(Vector3(4.0, 0.25, 2.0), roof.darkened(0.08), Vector3(0, 2.65, 0.55), root, Vector3(28, 0, 0))
	cylinder(0.2, 0.28, 0.9, Color("8d99ae"), Vector3(1.2, 2.95, 0), root, 5)


static func starter_shrine(pos: Vector3, parent: Node3D) -> Node3D:
	var shrine := Node3D.new()
	shrine.position = pos
	parent.add_child(shrine)
	# Circular platform
	cylinder(2.8, 2.8, 0.25, Color("d8e2dc"), Vector3(0, 0.12, 0), shrine, 10)
	cylinder(2.2, 2.2, 0.18, Color("264653"), Vector3(0, 0.32, 0), shrine, 10)
	for i in 3:
		var angle := deg_to_rad(i * 120.0)
		var offset := Vector3(cos(angle) * 1.5, 0, sin(angle) * 1.5)
		cylinder(0.18, 0.12, 1.4, Color("e9c46a"), offset + Vector3(0, 1.0, 0), shrine, 5)
		sphere(0.22, Color("fefae0"), offset + Vector3(0, 1.85, 0), shrine, 6)
	return shrine


static func forest_arch(pos: Vector3, parent: Node3D) -> void:
	box(Vector3(0.5, 3.2, 0.5), Color("6f4e37"), pos + Vector3(-2.8, 1.6, 0), parent)
	box(Vector3(0.5, 3.2, 0.5), Color("6f4e37"), pos + Vector3(2.8, 1.6, 0), parent)
	box(Vector3(6.2, 0.45, 0.55), Color("588157"), pos + Vector3(0, 3.35, 0), parent)
	box(Vector3(5.2, 0.3, 0.4), Color("40916c"), pos + Vector3(0, 3.7, 0), parent)


static func lamp_post(pos: Vector3, parent: Node3D) -> void:
	cylinder(0.08, 0.1, 2.2, Color("264653"), pos + Vector3(0, 1.1, 0), parent, 5)
	sphere(0.22, Color("ffd166"), pos + Vector3(0, 2.35, 0), parent, 6)


static func rock(pos: Vector3, parent: Node3D, size: float = 1.0) -> void:
	box(Vector3(0.9, 0.5, 0.8) * size, Color("8d99ae"), pos + Vector3(0, 0.25 * size, 0), parent, Vector3(0, randf_range(0, 40), randf_range(0, 40)))
	box(Vector3(0.5, 0.35, 0.6) * size, Color("6c757d"), pos + Vector3(0.2, 0.55 * size, 0.1), parent, Vector3(10, 25, -15))
