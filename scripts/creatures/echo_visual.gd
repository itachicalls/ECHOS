extends Node3D

## Builds recognizable low-poly Echo silhouettes per species.


func setup_from_definition(def: EchoDefinition) -> void:
	for c in get_children():
		c.queue_free()
	if def == null:
		return
	match def.id:
		"emberkit", "flarefox":
			_build_emberkit(def)
		"tideling", "marrowl":
			_build_tideling(def)
		"mossprite", "bramblekin":
			_build_mossprite(def)
		"pebblit":
			_build_pebblit(def)
		"zephyette":
			_build_zephyette(def)
		"duskip":
			_build_duskip(def)
		_:
			_build_generic(def)


func _build_emberkit(def: EchoDefinition) -> void:
	var c := def.color
	var big := def.id == "flarefox"
	var s := 1.25 if big else 1.0
	LowPolyKit.sphere(0.38 * s, c, Vector3(0, 0.42 * s, 0), self, 8)
	LowPolyKit.sphere(0.28 * s, c.lightened(0.1), Vector3(0, 0.78 * s, 0.12 * s), self, 8)
	LowPolyKit.cone(0.08 * s, 0.35 * s, c.lightened(0.2), Vector3(-0.18 * s, 1.0 * s, 0), self, 4)
	LowPolyKit.cone(0.08 * s, 0.35 * s, c.lightened(0.2), Vector3(0.18 * s, 1.0 * s, 0), self, 4)
	LowPolyKit.cone(0.12 * s, 0.5 * s, Color("ffd166"), Vector3(0, 0.55 * s, -0.35 * s), self, 4)
	LowPolyKit.box(Vector3(0.12 * s, 0.08 * s, 0.18 * s), Color("1d3557"), Vector3(-0.1 * s, 0.82 * s, 0.28 * s), self)
	LowPolyKit.box(Vector3(0.12 * s, 0.08 * s, 0.18 * s), Color("1d3557"), Vector3(0.1 * s, 0.82 * s, 0.28 * s), self)
	_add_shadow(s)


func _build_tideling(def: EchoDefinition) -> void:
	var c := def.color
	var big := def.id == "marrowl"
	var s := 1.2 if big else 1.0
	LowPolyKit.sphere(0.42 * s, c, Vector3(0, 0.38 * s, 0), self, 10)
	LowPolyKit.sphere(0.25 * s, c.lightened(0.15), Vector3(0, 0.62 * s, 0.18 * s), self, 8)
	LowPolyKit.box(Vector3(0.35 * s, 0.1 * s, 0.2 * s), c.darkened(0.1), Vector3(0, 0.45 * s, -0.28 * s), self)
	LowPolyKit.sphere(0.08 * s, Color("1d3557"), Vector3(-0.08 * s, 0.66 * s, 0.3 * s), self, 4)
	LowPolyKit.sphere(0.08 * s, Color("1d3557"), Vector3(0.08 * s, 0.66 * s, 0.3 * s), self, 4)
	if big:
		LowPolyKit.sphere(0.35 * s, c.darkened(0.15), Vector3(0, 0.35 * s, -0.35 * s), self, 8)
	_add_shadow(s)


func _build_mossprite(def: EchoDefinition) -> void:
	var c := def.color
	var big := def.id == "bramblekin"
	var s := 1.15 if big else 1.0
	LowPolyKit.cylinder(0.22 * s, 0.28 * s, 0.55 * s, c, Vector3(0, 0.35 * s, 0), self, 6)
	LowPolyKit.sphere(0.3 * s, c.lightened(0.12), Vector3(0, 0.78 * s, 0.05 * s), self, 8)
	for i in 3:
		var angle := deg_to_rad(i * 120.0)
		LowPolyKit.box(Vector3(0.08 * s, 0.35 * s, 0.22 * s), Color("40916c"), Vector3(cos(angle) * 0.12 * s, 1.05 * s, sin(angle) * 0.08 * s), self, Vector3(0, angle * 57.3, 20))
	if big:
		LowPolyKit.box(Vector3(0.5 * s, 0.12 * s, 0.35 * s), c.darkened(0.2), Vector3(0, 0.25 * s, -0.2 * s), self)
	LowPolyKit.sphere(0.07 * s, Color("1d3557"), Vector3(-0.1 * s, 0.8 * s, 0.2 * s), self, 4)
	LowPolyKit.sphere(0.07 * s, Color("1d3557"), Vector3(0.1 * s, 0.8 * s, 0.2 * s), self, 4)
	_add_shadow(s)


func _build_pebblit(def: EchoDefinition) -> void:
	var c := def.color
	LowPolyKit.box(Vector3(0.7, 0.55, 0.65), c, Vector3(0, 0.35, 0), self, Vector3(0, 15, 8))
	LowPolyKit.box(Vector3(0.45, 0.35, 0.4), c.lightened(0.08), Vector3(0.15, 0.62, 0.1), self, Vector3(-10, 30, 0))
	LowPolyKit.sphere(0.06, Color("1d3557"), Vector3(-0.12, 0.55, 0.28), self, 4)
	LowPolyKit.sphere(0.06, Color("1d3557"), Vector3(0.12, 0.55, 0.28), self, 4)
	_add_shadow(1.0)


func _build_zephyette(def: EchoDefinition) -> void:
	var c := def.color
	LowPolyKit.box(Vector3(0.25, 0.2, 0.7), c, Vector3(0, 0.55, 0), self)
	LowPolyKit.sphere(0.22, c.lightened(0.2), Vector3(0, 0.72, 0.25), self, 6)
	LowPolyKit.box(Vector3(0.45, 0.04, 0.25), c.darkened(0.05), Vector3(0, 0.6, -0.05), self, Vector3(30, 0, 0))
	LowPolyKit.box(Vector3(0.45, 0.04, 0.25), c.darkened(0.05), Vector3(0, 0.6, 0.05), self, Vector3(-30, 0, 0))
	LowPolyKit.sphere(0.05, Color("1d3557"), Vector3(-0.08, 0.76, 0.35), self, 4)
	LowPolyKit.sphere(0.05, Color("1d3557"), Vector3(0.08, 0.76, 0.35), self, 4)
	_add_shadow(1.0)


func _build_duskip(def: EchoDefinition) -> void:
	var c := def.color
	LowPolyKit.sphere(0.35, c, Vector3(0, 0.42, 0), self, 8)
	LowPolyKit.sphere(0.22, c.lightened(0.1), Vector3(0, 0.72, 0.08), self, 8)
	LowPolyKit.cone(0.1, 0.28, c.darkened(0.15), Vector3(-0.2, 0.88, 0), self, 4)
	LowPolyKit.cone(0.1, 0.28, c.darkened(0.15), Vector3(0.2, 0.88, 0), self, 4)
	LowPolyKit.sphere(0.08, Color("ffd166"), Vector3(-0.1, 0.74, 0.24), self, 4)
	LowPolyKit.sphere(0.08, Color("ffd166"), Vector3(0.1, 0.74, 0.24), self, 4)
	_add_shadow(1.0)


func _build_generic(def: EchoDefinition) -> void:
	LowPolyKit.sphere(0.4, def.color, Vector3(0, 0.45, 0), self, 8)
	LowPolyKit.sphere(0.25, def.color.lightened(0.15), Vector3(0, 0.82, 0.1), self, 8)
	_add_shadow(1.0)


func _add_shadow(scale: float) -> void:
	var shadow := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.bottom_radius = 0.42 * scale
	cyl.top_radius = 0.42 * scale
	cyl.height = 0.02
	shadow.mesh = cyl
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0, 0, 0, 0.2)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow.material_override = m
	shadow.position = Vector3(0, 0.01, 0)
	add_child(shadow)
