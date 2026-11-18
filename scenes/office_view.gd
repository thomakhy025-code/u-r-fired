class_name OfficeView
extends SubViewportContainer

## Cutaway office. People are simple 3D figures who sit and work.

signal seat_pressed(seat: int)

const STAFF := {
	"mina": {"shirt": Color("2a9d8f"), "hair": Color("241c18"), "skin": Color("f3c7a8")},
	"june": {"shirt": Color("3d5a80"), "hair": Color("6d4030"), "skin": Color("f6d3b8")},
	"otto": {"shirt": Color("e07a3d"), "hair": Color("d7b072"), "skin": Color("efc09a")},
	"ben": {"shirt": Color("c4495a"), "hair": Color("2c2622"), "skin": Color("e8b898")},
}

var viewport: SubViewport
var camera: Camera3D
var game: GameState
var workers := {}
var director: Node3D
var clock := 0.0


func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(0, 460)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.transparent_bg = false
	viewport.handle_input_locally = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_2X
	add_child(viewport)
	_build_world()
	call_deferred("_fit")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_fit()


func _fit() -> void:
	if viewport == null:
		return
	var next := Vector2i(maxi(int(size.x), 2), maxi(int(size.y), 2))
	if viewport.size != next:
		viewport.size = next


func bind_game(next: GameState) -> void:
	game = next
	sync_staff()


func sync_staff() -> void:
	if game == null:
		return
	for id in STAFF.keys():
		var hired := false
		for person in game.hired_people():
			if person.id == id:
				hired = true
				_show_worker(id, person)
		if not hired and workers.has(id):
			(workers[id] as Node3D).visible = false


func _gui_input(event: InputEvent) -> void:
	if game == null or camera == null:
		return
	if not (event is InputEventMouseButton):
		return
	var click := event as InputEventMouseButton
	if not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	var mouse := click.position * Vector2(viewport.size) / Vector2(maxi(size.x, 1.0), maxi(size.y, 1.0))
	var best := -999
	var best_distance := 64.0
	var points := {"director": camera.unproject_position(director.global_position + Vector3(0, 1.0, 0))}
	for id in workers.keys():
		var body: Node3D = workers[id]
		if not body.visible:
			continue
		points[id] = camera.unproject_position(body.global_position + Vector3(0, 1.0, 0))
	for key in points.keys():
		var distance: float = (points[key] as Vector2).distance_to(mouse)
		if distance < best_distance:
			best_distance = distance
			if key == "director":
				best = -1
			else:
				best = game.person(str(key)).seat
	if best != -999:
		seat_pressed.emit(best)
		accept_event()


func _process(delta: float) -> void:
	clock += delta
	if director != null:
		director.position.y = sin(clock * 1.6) * 0.015
	if game == null:
		return
	for person in game.hired_people():
		if not workers.has(person.id):
			continue
		var body: Node3D = workers[person.id]
		var arms: Node3D = body.get_node("Arms")
		var book: Node3D = body.get_node("Book")
		if person.training:
			book.visible = true
			arms.rotation.x = sin(clock * 1.4) * 0.08
		else:
			book.visible = false
			var pace := 0.7 + game.heart_scale(person.love) * 1.8 + float(person.base_pace) * 0.15
			arms.rotation.x = sin(clock * 7.0 * pace + float(person.seat)) * 0.28
		var label: Label3D = body.get_node("Name")
		label.text = "%s\n%s" % [person.display_name, game.hearts(person.love)]


func _build_world() -> void:
	var root := Node3D.new()
	viewport.add_child(root)
	var env := WorldEnvironment.new()
	var world := Environment.new()
	world.background_mode = Environment.BG_COLOR
	world.background_color = Color("d7eef8")
	world.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.ambient_light_color = Color("fff6ea")
	world.ambient_light_energy = 0.85
	env.environment = world
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, 38, 0)
	sun.light_color = Color("fff4dd")
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	root.add_child(sun)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 9.2
	camera.look_at_from_position(Vector3(9.5, 8.2, 9.5), Vector3(0.2, 0.4, 0.0))
	root.add_child(camera)

	_box(root, Vector3(0, -0.08, 0), Vector3(13.5, 0.16, 9.2), _wood())
	_box(root, Vector3(0, 0.01, -1.1), Vector3(7.4, 0.04, 4.6), _paint(Color("f6c7a1")))
	_box(root, Vector3(0, 1.35, -4.55), Vector3(13.5, 2.7, 0.18), _paint(Color("f7f1e8")))
	_box(root, Vector3(-6.65, 1.35, 0), Vector3(0.18, 2.7, 9.2), _paint(Color("f4ebe3")))
	_box(root, Vector3(2.2, 1.7, -4.42), Vector3(3.2, 1.5, 0.08), _paint(Color("9fd4ee")))
	_box(root, Vector3(2.2, 2.55, -4.42), Vector3(3.4, 0.12, 0.12), _paint(Color("f4f7fb")))
	_box(root, Vector3(2.2, 0.95, -4.42), Vector3(3.4, 0.12, 0.12), _paint(Color("f4f7fb")))
	_plant(root, Vector3(5.6, 0, 3.3))
	_plant(root, Vector3(-5.5, 0, 3.4))
	_plant(root, Vector3(5.7, 0, -3.2))
	_shelf(root, Vector3(-5.6, 0, -3.6))
	_lamp(root, Vector3(-1.2, 2.35, 0.4))
	_lamp(root, Vector3(2.6, 2.35, 0.4))

	var director_seat := Vector3(-4.15, 0, -2.7)
	_glass_room(root, director_seat)
	_place_worker(root, director_seat)
	director = _worker(root, Color("2f3544"), Color("3a2a22"), Color("f1c7a3"), "Director")
	director.position = director_seat

	var spots := [
		Vector3(-2.15, 0, 0.85),
		Vector3(1.55, 0, 0.85),
		Vector3(-2.15, 0, -1.15),
		Vector3(1.55, 0, -1.15),
	]
	var ids := ["mina", "june", "otto", "ben"]
	for i in spots.size():
		_place_worker(root, spots[i])
		var look: Dictionary = STAFF[ids[i]]
		var person := _worker(root, look["shirt"] as Color, look["hair"] as Color, look["skin"] as Color, "")
		person.position = spots[i]
		person.visible = false
		workers[ids[i]] = person
	sync_staff()


func _show_worker(id: String, person: GameState.Person) -> void:
	var body: Node3D = workers[id]
	body.visible = true
	var label: Label3D = body.get_node("Name")
	label.text = "%s\n%s" % [person.display_name, game.hearts(person.love)]


func _place_worker(parent: Node3D, seat: Vector3) -> void:
	_chair(parent, seat)
	_workstation(parent, seat + Vector3(0, 0, 0.72))


func _chair(parent: Node3D, at: Vector3) -> void:
	_box(parent, at + Vector3(0, 0.32, -0.02), Vector3(0.46, 0.08, 0.46), _paint(Color("e7d3b4")))
	_box(parent, at + Vector3(0, 0.58, -0.22), Vector3(0.46, 0.42, 0.08), _paint(Color("efe2cf")))
	for x in [-0.18, 0.18]:
		_box(parent, at + Vector3(x, 0.16, 0.16), Vector3(0.06, 0.32, 0.06), _paint(Color("c9a077")))
		_box(parent, at + Vector3(x, 0.16, -0.16), Vector3(0.06, 0.32, 0.06), _paint(Color("c9a077")))


func _workstation(parent: Node3D, at: Vector3) -> void:
	var desk := Node3D.new()
	desk.position = at
	parent.add_child(desk)
	_box(desk, Vector3(0, 0.74, 0), Vector3(1.28, 0.08, 0.68), _paint(Color("fffaf4")))
	for x in [-0.52, 0.52]:
		for z in [-0.24, 0.24]:
			_box(desk, Vector3(x, 0.36, z), Vector3(0.07, 0.72, 0.07), _paint(Color("d8b48a")))
	var screen := _box(desk, Vector3(0, 0.94, -0.24), Vector3(0.48, 0.26, 0.04), _paint(Color("243246")))
	var glow: StandardMaterial3D = screen.material_override
	glow.emission_enabled = true
	glow.emission = Color("8fd6ff")
	glow.emission_energy_multiplier = 0.35
	_box(desk, Vector3(0, 0.82, -0.24), Vector3(0.08, 0.12, 0.05), _paint(Color("d9c3a6")))
	_box(desk, Vector3(0, 0.79, 0.08), Vector3(0.28, 0.02, 0.12), _paint(Color("d7dde6")))
	_box(desk, Vector3(0.36, 0.79, 0.02), Vector3(0.16, 0.02, 0.2), _paint(Color("f7fbfc")))
	_box(desk, Vector3(-0.38, 0.8, 0.04), Vector3(0.14, 0.035, 0.18), _paint(Color("f2d7b5")))
	var mug := MeshInstance3D.new()
	var cup := CylinderMesh.new()
	cup.top_radius = 0.05
	cup.bottom_radius = 0.045
	cup.height = 0.09
	mug.mesh = cup
	mug.position = Vector3(0.46, 0.84, 0.16)
	mug.material_override = _paint(Color("f4f7fb"))
	desk.add_child(mug)


func _glass_room(parent: Node3D, at: Vector3) -> void:
	var glass := _paint(Color("d5f3ef"))
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.78, 0.94, 0.92, 0.28)
	var trim := _paint(Color("f7f1e8"))
	_box(parent, at + Vector3(0, 0.42, -0.85), Vector3(2.5, 0.84, 0.06), glass)
	_box(parent, at + Vector3(-1.22, 0.42, 0.15), Vector3(0.06, 0.84, 1.35), glass)
	_box(parent, at + Vector3(1.22, 0.42, 0.15), Vector3(0.06, 0.84, 1.35), glass)
	_box(parent, at + Vector3(0, 0.86, -0.85), Vector3(2.55, 0.08, 0.08), trim)
	for corner in [Vector3(-1.22, 0.42, -0.85), Vector3(1.22, 0.42, -0.85), Vector3(-1.22, 0.42, 0.82), Vector3(1.22, 0.42, 0.82)]:
		_box(parent, at + corner, Vector3(0.1, 0.9, 0.1), trim)


func _worker(parent: Node3D, shirt: Color, hair: Color, skin: Color, title: String) -> Node3D:
	var person := Node3D.new()
	parent.add_child(person)
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.18
	capsule.height = 0.4
	body.mesh = capsule
	body.position = Vector3(0, 0.52, 0)
	body.material_override = _paint(shirt)
	person.add_child(body)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.23
	sphere.height = 0.46
	head.mesh = sphere
	head.position = Vector3(0, 0.86, 0)
	head.material_override = _paint(skin)
	person.add_child(head)
	var hair_mesh := MeshInstance3D.new()
	var hair_sphere := SphereMesh.new()
	hair_sphere.radius = 0.24
	hair_sphere.height = 0.3
	hair_mesh.mesh = hair_sphere
	hair_mesh.position = Vector3(0, 0.98, -0.03)
	hair_mesh.material_override = _paint(hair)
	person.add_child(hair_mesh)
	for side in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var dot := SphereMesh.new()
		dot.radius = 0.028
		dot.height = 0.056
		eye.mesh = dot
		eye.position = Vector3(0.08 * side, 0.88, 0.19)
		eye.material_override = _paint(Color("2b241c"))
		person.add_child(eye)
	var arms := Node3D.new()
	arms.name = "Arms"
	arms.position = Vector3(0, 0.62, 0.1)
	person.add_child(arms)
	for side in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		var limb := CapsuleMesh.new()
		limb.radius = 0.05
		limb.height = 0.28
		arm.mesh = limb
		arm.position = Vector3(0.24 * side, -0.08, 0.08)
		arm.rotation_degrees.x = 70
		arm.material_override = _paint(shirt)
		arms.add_child(arm)
	var book := MeshInstance3D.new()
	book.name = "Book"
	var pages := BoxMesh.new()
	pages.size = Vector3(0.22, 0.05, 0.16)
	book.mesh = pages
	book.position = Vector3(0, 0.7, 0.3)
	book.material_override = _paint(Color("f4efe4"))
	book.visible = false
	person.add_child(book)
	var label := Label3D.new()
	label.name = "Name"
	label.text = title
	label.position = Vector3(0, 1.28, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 42
	label.pixel_size = 0.0045
	label.modulate = Color("2c261f")
	label.outline_size = 10
	label.outline_modulate = Color("fffaf3")
	label.no_depth_test = true
	person.add_child(label)
	return person


func _plant(parent: Node3D, at: Vector3) -> void:
	_box(parent, at + Vector3(0, 0.16, 0), Vector3(0.28, 0.32, 0.28), _paint(Color("e07a4c")))
	var puff := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.28
	ball.height = 0.56
	puff.mesh = ball
	puff.position = at + Vector3(0, 0.52, 0)
	puff.material_override = _paint(Color("67b96a"))
	parent.add_child(puff)


func _shelf(parent: Node3D, at: Vector3) -> void:
	_box(parent, at + Vector3(0, 0.7, 0), Vector3(1.1, 1.4, 0.28), _paint(Color("e6c89a")))
	_box(parent, at + Vector3(-0.22, 0.95, 0.08), Vector3(0.16, 0.42, 0.12), _paint(Color("d4574e")))
	_box(parent, at + Vector3(0.05, 0.95, 0.08), Vector3(0.16, 0.42, 0.12), _paint(Color("3d8f86")))
	_box(parent, at + Vector3(0.3, 0.88, 0.08), Vector3(0.14, 0.28, 0.12), _paint(Color("e0b15a")))


func _lamp(parent: Node3D, at: Vector3) -> void:
	var shade := _paint(Color("ffe7a3"))
	shade.emission_enabled = true
	shade.emission = Color("ffd98a")
	shade.emission_energy_multiplier = 0.25
	_box(parent, at, Vector3(0.42, 0.06, 0.42), shade)


func _box(parent: Node3D, at: Vector3, extents: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = extents
	mesh_instance.mesh = box
	mesh_instance.position = at
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	return mesh_instance


func _paint(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	material.specular_mode = BaseMaterial3D.SPECULAR_TOON
	return material


func _wood() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode diffuse_toon, specular_toon; void fragment() { vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; float band = fract(world.x * 0.85); float seam = step(0.06, band); float end_grain = step(0.94, fract(world.z * 0.45)); vec3 plank = mix(vec3(0.62, 0.42, 0.24), vec3(0.84, 0.64, 0.40), seam); ALBEDO = mix(plank * 0.78, plank, end_grain); }"
	var material := ShaderMaterial.new()
	material.shader = shader
	return material
