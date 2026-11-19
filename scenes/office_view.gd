class_name OfficeView
extends SubViewportContainer

## Cutaway office. People are simple 3D figures who sit and work.

signal seat_pressed(seat: int)

const LOOKS := {
	"mina": {"shirt": Color("2f7d72"), "hair": Color("241c18"), "skin": Color("e2b896")},
	"june": {"shirt": Color("3d5a80"), "hair": Color("6d4030"), "skin": Color("e8c4a8")},
	"otto": {"shirt": Color("c46a32"), "hair": Color("c4a060"), "skin": Color("dcb08a")},
	"ben": {"shirt": Color("a33d4e"), "hair": Color("2c2622"), "skin": Color("d4a888")},
	"rosa": {"shirt": Color("6e4d78"), "hair": Color("2a1814"), "skin": Color("e0b090")},
	"ken": {"shirt": Color("3f6b4a"), "hair": Color("1e1a16"), "skin": Color("d8b090")},
	"priya": {"shirt": Color("8a5a3a"), "hair": Color("1a1412"), "skin": Color("c48a62")},
	"sam": {"shirt": Color("3d6a8a"), "hair": Color("d4b48a"), "skin": Color("efc4a4")},
	"noor": {"shirt": Color("8a3d48"), "hair": Color("3a241c"), "skin": Color("e2b898")},
}

const TOY_LIGHT := """
void light() {
	float facing = dot(NORMAL, LIGHT);
	float band = step(0.22, facing);
	float shade = mix(0.5, 0.74, band);
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * ATTENUATION * shade;
}
"""

var viewport: SubViewport
var camera: Camera3D
var game: GameState
var seats: Array[Node3D] = []
var director: Node3D
var phone: Node3D
var phone_lamp: MeshInstance3D
var ready_boxes: Array[MeshInstance3D] = []
var ready_label: Label3D
var clock := 0.0
var _toy: Shader
var _wood_shader: Shader
var _fade: Shader


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
	for seat in seats.size():
		var body: Node3D = seats[seat]
		var sitting: GameState.Person = null
		for person in game.hired_people():
			if person.seat == seat:
				sitting = person
				break
		if sitting == null:
			body.visible = false
			continue
		body.visible = true
		_dress(body, sitting.id)
		var label: Label3D = body.get_node("Name")
		label.text = "%s\n%s %s" % [sitting.display_name, game.hearts(sitting.love), _mood(sitting.love)]
	_sync_outbox()


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
	var best_distance := 80.0
	var points := {"director": camera.unproject_position(director.global_position + Vector3(0, 1.0, 0))}
	if phone != null:
		points["phone"] = camera.unproject_position(phone.global_position + Vector3(0, 0.7, 0))
	for seat in seats.size():
		var body: Node3D = seats[seat]
		if not body.visible:
			continue
		points[str(seat)] = camera.unproject_position(body.global_position + Vector3(0, 1.0, 0))
	for key in points.keys():
		var distance: float = (points[key] as Vector2).distance_to(mouse)
		if distance < best_distance:
			best_distance = distance
			if str(key) == "director":
				best = -1
			elif str(key) == "phone":
				best = -2
			else:
				best = int(key)
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
		if person.seat < 0 or person.seat >= seats.size():
			continue
		var body: Node3D = seats[person.seat]
		var arms: Node3D = body.get_node("Arms")
		var book: Node3D = body.get_node("Book")
		var working: bool = person.training
		if not working:
			for deal in game.deals:
				var stage := str(deal["stage"])
				if stage == "closed" or stage == "offer" or stage == "quality":
					continue
				if (deal["crew"] as Array).has(person.id):
					working = true
					break
		var label: Label3D = body.get_node("Name")
		label.text = "%s\n%s %s" % [person.display_name, game.hearts(person.love), _mood(person.love)]
		if person.training:
			book.visible = true
			arms.rotation.x = sin(clock * 1.4) * 0.08
		else:
			book.visible = working
			var pace := 0.7 + game.heart_scale(person.love) * 1.8 + float(person.base_pace) * 0.15
			arms.rotation.x = sin(clock * 7.0 * pace + float(person.seat)) * 0.28
	_ring_phone()


func _mood(love: int) -> String:
	if love >= 4:
		return "glad"
	if love >= 3:
		return "steady"
	if love >= 2:
		return "cool"
	return "upset"


func _ring_phone() -> void:
	if phone == null or phone_lamp == null:
		return
	var ringing := false
	for deal in game.deals:
		if str(deal["kind"]) == "customer" and str(deal["stage"]) == "offer":
			ringing = true
			break
	var flash := ringing and sin(clock * 10.0) > 0.0
	phone.position.y = 0.05 if flash else 0.0
	_set_albedo(phone_lamp, Color("e23b3b") if flash else Color("7a3030"))


func _sync_outbox() -> void:
	if ready_label == null:
		return
	ready_label.text = "Ready\n%d" % game.stock
	var shown := 0
	if game.stock > 0:
		shown = clampi(int(ceil(float(game.stock) / 8.0)), 1, ready_boxes.size())
	for i in ready_boxes.size():
		ready_boxes[i].visible = i < shown


func _build_world() -> void:
	var root := Node3D.new()
	viewport.add_child(root)
	var env := WorldEnvironment.new()
	var world := Environment.new()
	world.background_mode = Environment.BG_COLOR
	world.background_color = Color("4e94b8")
	world.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.ambient_light_color = Color("f2d2b0")
	world.ambient_light_energy = 0.24
	world.tonemap_mode = Environment.TONE_MAPPER_ACES
	world.tonemap_exposure = 0.84
	world.adjustment_enabled = true
	world.adjustment_brightness = 0.92
	world.adjustment_contrast = 1.06
	world.adjustment_saturation = 1.08
	env.environment = world
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, 32, 0)
	sun.light_color = Color("ffe0b0")
	sun.light_energy = 0.78
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.55
	root.add_child(sun)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 7.6
	camera.look_at_from_position(Vector3(9.2, 5.6, 9.2), Vector3(-0.2, 0.7, -0.1))
	root.add_child(camera)

	_box(root, Vector3(0, -0.08, 0), Vector3(13.2, 0.16, 9.0), _wood())
	_box(root, Vector3(-0.35, 0.02, 0.15), Vector3(3.4, 0.03, 2.2), _rug())
	_box(root, Vector3(0, 1.25, -4.48), Vector3(13.2, 2.5, 0.18), _paint(Color("e08958")))
	_box(root, Vector3(0, 0.42, -4.36), Vector3(13.2, 0.84, 0.08), _paint(Color("f0c27a")))
	_box(root, Vector3(-6.5, 1.25, 0), Vector3(0.18, 2.5, 9.0), _paint(Color("d97848")))
	_box(root, Vector3(-6.38, 0.42, 0), Vector3(0.08, 0.84, 9.0), _paint(Color("f0c27a")))
	_box(root, Vector3(2.15, 1.55, -4.34), Vector3(2.7, 1.25, 0.06), _paint(Color("7ec8e3")))
	_box(root, Vector3(2.15, 2.22, -4.32), Vector3(2.95, 0.1, 0.1), _paint(Color("a56b3c")))
	_box(root, Vector3(2.15, 0.88, -4.32), Vector3(2.95, 0.1, 0.1), _paint(Color("a56b3c")))
	_box(root, Vector3(0.85, 1.55, -4.32), Vector3(0.08, 1.35, 0.1), _paint(Color("a56b3c")))
	_box(root, Vector3(3.45, 1.55, -4.32), Vector3(0.08, 1.35, 0.1), _paint(Color("a56b3c")))
	_plant(root, Vector3(5.15, 0, 2.85))
	_plant(root, Vector3(-5.35, 0, 2.9))
	_plant(root, Vector3(5.2, 0, -2.7))
	_shelf(root, Vector3(-5.45, 0, -3.15))
	phone = _phone(root, Vector3(4.35, 0, 2.35))
	_outbox(root, Vector3(4.55, 0, -0.15))
	_lamp(root, Vector3(-0.4, 2.15, 0.2))
	_lamp(root, Vector3(2.8, 2.15, 0.2))

	var director_seat := Vector3(-4.15, 0, -2.7)
	_glass_room(root, director_seat)
	_place_worker(root, director_seat, Color("d9b48a"))
	director = _worker(root, Color("2f3544"), Color("3a2a22"), Color("f1c7a3"), "Director")
	director.position = director_seat

	var spots := [
		Vector3(-2.55, 0, 1.25),
		Vector3(1.85, 0, 1.25),
		Vector3(-2.55, 0, -1.45),
		Vector3(1.85, 0, -1.45),
	]
	var mats := [Color("3faf8a"), Color("e0a04a"), Color("3d8ec4"), Color("e06a58")]
	for i in spots.size():
		_place_worker(root, spots[i], mats[i])
		var person := _worker(root, Color("5f8f78"), Color("241c18"), Color("e2b896"), "")
		person.position = spots[i]
		person.visible = false
		seats.append(person)
	sync_staff()


func _dress(body: Node3D, id: String) -> void:
	var look: Dictionary = LOOKS.get(id, {"shirt": Color("5f7d68"), "hair": Color("2c241c"), "skin": Color("e2b896")})
	var shirt: Color = look["shirt"]
	var skin: Color = look["skin"]
	var hair: Color = look["hair"]
	_set_albedo(body.get_node("Shirt"), shirt)
	_set_albedo(body.get_node("Skin"), skin)
	_set_albedo(body.get_node("Hair"), hair)
	for arm in body.get_node("Arms").get_children():
		_set_albedo(arm, shirt)


func _set_albedo(node: Node, color: Color) -> void:
	var mesh := node as MeshInstance3D
	if mesh == null:
		return
	var material := mesh.material_override as ShaderMaterial
	if material != null:
		material.set_shader_parameter("albedo", color)


func _place_worker(parent: Node3D, seat: Vector3, mat: Color) -> void:
	_shadow(parent, seat + Vector3(0, 0, 0.35), Vector2(1.35, 1.15))
	_chair(parent, seat)
	_workstation(parent, seat + Vector3(0, 0, 0.78), mat)


func _shadow(parent: Node3D, at: Vector3, extents: Vector2) -> void:
	_box(parent, at + Vector3(0, 0.02, 0), Vector3(extents.x, 0.015, extents.y), _glass(Color(0.28, 0.16, 0.08, 0.35)))


func _chair(parent: Node3D, at: Vector3) -> void:
	_box(parent, at + Vector3(0, 0.34, -0.02), Vector3(0.5, 0.09, 0.48), _paint(Color("c9844e")))
	_box(parent, at + Vector3(0, 0.62, -0.24), Vector3(0.5, 0.46, 0.09), _paint(Color("b8733e")))
	for x in [-0.19, 0.19]:
		_box(parent, at + Vector3(x, 0.16, 0.16), Vector3(0.07, 0.32, 0.07), _paint(Color("8a542c")))
		_box(parent, at + Vector3(x, 0.16, -0.16), Vector3(0.07, 0.32, 0.07), _paint(Color("8a542c")))


func _workstation(parent: Node3D, at: Vector3, mat: Color) -> void:
	var desk := Node3D.new()
	desk.position = at
	parent.add_child(desk)
	_box(desk, Vector3(0, 0.7, 0), Vector3(1.34, 0.1, 0.72), _paint(Color("a07a48")))
	_box(desk, Vector3(0, 0.76, 0.02), Vector3(0.72, 0.025, 0.4), _paint(mat))
	for x in [-0.54, 0.54]:
		for z in [-0.26, 0.26]:
			_box(desk, Vector3(x, 0.34, z), Vector3(0.08, 0.68, 0.08), _paint(Color("8d5a32")))
	_box(desk, Vector3(0, 0.98, -0.22), Vector3(0.58, 0.36, 0.05), _paint(Color("24384a")))
	_box(desk, Vector3(0, 0.99, -0.19), Vector3(0.48, 0.26, 0.02), _paint(Color("3f8eb0")))
	_box(desk, Vector3(0, 0.8, -0.22), Vector3(0.08, 0.14, 0.05), _paint(Color("8d5a32")))
	_box(desk, Vector3(0, 0.77, 0.1), Vector3(0.32, 0.025, 0.14), _paint(Color("5d6b78")))
	_box(desk, Vector3(0.38, 0.77, 0.02), Vector3(0.18, 0.02, 0.22), _paint(Color("f4efe4")))
	_box(desk, Vector3(-0.4, 0.78, 0.04), Vector3(0.16, 0.04, 0.18), _paint(Color("e7c9a0")))
	var mug := MeshInstance3D.new()
	var cup := CylinderMesh.new()
	cup.top_radius = 0.055
	cup.bottom_radius = 0.048
	cup.height = 0.1
	mug.mesh = cup
	mug.position = Vector3(0.48, 0.82, 0.16)
	mug.material_override = _paint(Color("f2efe6"))
	desk.add_child(mug)


func _glass_room(parent: Node3D, at: Vector3) -> void:
	var glass := _glass(Color(0.55, 0.78, 0.74, 0.45))
	var trim := _paint(Color("a56b3c"))
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
	body.name = "Shirt"
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.22
	capsule.height = 0.46
	body.mesh = capsule
	body.position = Vector3(0, 0.58, 0)
	body.material_override = _paint(shirt)
	person.add_child(body)
	var head := MeshInstance3D.new()
	head.name = "Skin"
	var sphere := SphereMesh.new()
	sphere.radius = 0.28
	sphere.height = 0.56
	head.mesh = sphere
	head.position = Vector3(0, 0.98, 0)
	head.material_override = _paint(skin)
	person.add_child(head)
	var hair_mesh := MeshInstance3D.new()
	hair_mesh.name = "Hair"
	var hair_sphere := SphereMesh.new()
	hair_sphere.radius = 0.26
	hair_sphere.height = 0.28
	hair_mesh.mesh = hair_sphere
	hair_mesh.position = Vector3(0, 1.16, -0.14)
	hair_mesh.material_override = _paint(hair)
	person.add_child(hair_mesh)
	for side in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var dot := SphereMesh.new()
		dot.radius = 0.035
		dot.height = 0.07
		eye.mesh = dot
		eye.position = Vector3(0.09 * side, 1.0, 0.23)
		eye.material_override = _paint(Color("2b241c"))
		person.add_child(eye)
	var arms := Node3D.new()
	arms.name = "Arms"
	arms.position = Vector3(0, 0.68, 0.12)
	person.add_child(arms)
	for side in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		var limb := CapsuleMesh.new()
		limb.radius = 0.06
		limb.height = 0.32
		arm.mesh = limb
		arm.position = Vector3(0.28 * side, -0.08, 0.1)
		arm.rotation_degrees.x = 70
		arm.material_override = _paint(shirt)
		arms.add_child(arm)
	var book := MeshInstance3D.new()
	book.name = "Book"
	var pages := BoxMesh.new()
	pages.size = Vector3(0.22, 0.05, 0.16)
	book.mesh = pages
	book.position = Vector3(0, 0.78, 0.34)
	book.material_override = _paint(Color("f4efe4"))
	book.visible = false
	person.add_child(book)
	var label := Label3D.new()
	label.name = "Name"
	label.text = title
	label.position = Vector3(0, 1.48, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 42
	label.pixel_size = 0.0045
	label.modulate = Color("2c261f")
	label.outline_size = 10
	label.outline_modulate = Color("fffaf3")
	label.font = ThemeDB.fallback_font
	label.no_depth_test = true
	person.add_child(label)
	return person


func _phone(parent: Node3D, at: Vector3) -> Node3D:
	var desk := Node3D.new()
	desk.position = at
	parent.add_child(desk)
	_box(desk, Vector3(0, 0.62, 0), Vector3(1.15, 0.1, 0.7), _paint(Color("f2d2a8")))
	for x in [-0.46, 0.46]:
		for z in [-0.26, 0.26]:
			_box(desk, Vector3(x, 0.3, z), Vector3(0.08, 0.58, 0.08), _paint(Color("c9844e")))
	_box(desk, Vector3(0, 0.74, 0.02), Vector3(0.42, 0.08, 0.28), _paint(Color("f7f1e4")))
	_box(desk, Vector3(-0.1, 0.86, 0.02), Vector3(0.22, 0.08, 0.1), _paint(Color("2f3544")))
	phone_lamp = _box(desk, Vector3(0.22, 0.86, 0.08), Vector3(0.1, 0.1, 0.1), _paint(Color("7a3030")))
	var sign := Label3D.new()
	sign.text = "Phone"
	sign.position = Vector3(0, 1.25, 0)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.font_size = 48
	sign.pixel_size = 0.004
	sign.modulate = Color("2c261f")
	sign.outline_size = 8
	sign.outline_modulate = Color("fffaf3")
	sign.font = ThemeDB.fallback_font
	sign.no_depth_test = true
	desk.add_child(sign)
	return desk


func _outbox(parent: Node3D, at: Vector3) -> void:
	var counter := Node3D.new()
	counter.position = at
	parent.add_child(counter)
	_box(counter, Vector3(0, 0.58, 0), Vector3(1.5, 0.12, 0.7), _paint(Color("f7f1e4")))
	_box(counter, Vector3(0, 0.28, 0), Vector3(1.4, 0.48, 0.62), _paint(Color("e06a58")))
	var colors := [Color("3faf8a"), Color("e0a04a"), Color("3d8ec4"), Color("f2d2a8")]
	for i in colors.size():
		var parcel := _box(counter, Vector3(-0.48 + float(i) * 0.32, 0.78, 0.02), Vector3(0.26, 0.22, 0.26), _paint(colors[i]))
		parcel.visible = false
		ready_boxes.append(parcel)
	ready_label = Label3D.new()
	ready_label.text = "Ready\n0"
	ready_label.position = Vector3(0, 1.25, 0)
	ready_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ready_label.font_size = 42
	ready_label.pixel_size = 0.004
	ready_label.modulate = Color("2c261f")
	ready_label.outline_size = 8
	ready_label.outline_modulate = Color("fffaf3")
	ready_label.font = ThemeDB.fallback_font
	ready_label.no_depth_test = true
	counter.add_child(ready_label)


func _rug() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode cull_back, specular_disabled; void fragment() { vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; float cx = step(0.5, fract(world.x * 1.1)); float cz = step(0.5, fract(world.z * 1.1)); float check = abs(cx - cz); ALBEDO = mix(vec3(0.86, 0.32, 0.28), vec3(0.96, 0.78, 0.48), check); }\n" + TOY_LIGHT
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _plant(parent: Node3D, at: Vector3) -> void:
	_box(parent, at + Vector3(0, 0.18, 0), Vector3(0.34, 0.36, 0.34), _paint(Color("c4512f")))
	var puff := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.36
	ball.height = 0.72
	puff.mesh = ball
	puff.position = at + Vector3(0, 0.62, 0)
	puff.material_override = _paint(Color("2f8f45"))
	parent.add_child(puff)


func _shelf(parent: Node3D, at: Vector3) -> void:
	_box(parent, at + Vector3(0, 0.75, 0), Vector3(1.15, 1.5, 0.3), _paint(Color("a86b3c")))
	_box(parent, at + Vector3(-0.24, 1.0, 0.1), Vector3(0.16, 0.46, 0.12), _paint(Color("c4494a")))
	_box(parent, at + Vector3(0.02, 1.0, 0.1), Vector3(0.16, 0.46, 0.12), _paint(Color("2f8a78")))
	_box(parent, at + Vector3(0.28, 0.92, 0.1), Vector3(0.14, 0.3, 0.12), _paint(Color("e0a04a")))


func _lamp(parent: Node3D, at: Vector3) -> void:
	_box(parent, at, Vector3(0.08, 0.7, 0.08), _paint(Color("8a542c")))
	_box(parent, at + Vector3(0, -0.28, 0), Vector3(0.55, 0.08, 0.55), _paint(Color("e2a84a")))


func _box(parent: Node3D, at: Vector3, extents: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = extents
	mesh_instance.mesh = box
	mesh_instance.position = at
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	return mesh_instance


func _paint(color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = _shared_toy()
	material.set_shader_parameter("albedo", color)
	return material


func _glass(color: Color) -> ShaderMaterial:
	if _fade == null:
		_fade = Shader.new()
		_fade.code = "shader_type spatial; render_mode blend_mix, depth_draw_opaque, cull_back, specular_disabled; uniform vec4 albedo : source_color = vec4(1.0); void fragment() { ALBEDO = albedo.rgb; ALPHA = albedo.a; }\n" + TOY_LIGHT
	var material := ShaderMaterial.new()
	material.shader = _fade
	material.set_shader_parameter("albedo", color)
	return material


func _shared_toy() -> Shader:
	if _toy != null:
		return _toy
	_toy = Shader.new()
	_toy.code = "shader_type spatial; render_mode cull_back, specular_disabled; uniform vec4 albedo : source_color = vec4(1.0); void fragment() { ALBEDO = albedo.rgb; }\n" + TOY_LIGHT
	return _toy


func _wood() -> ShaderMaterial:
	if _wood_shader == null:
		_wood_shader = Shader.new()
		_wood_shader.code = "shader_type spatial; render_mode specular_disabled; void fragment() { vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; float band = fract(world.x * 0.72); float seam = step(0.055, band); float grain = step(0.88, fract(world.z * 0.5)); vec3 plank = mix(vec3(0.55, 0.32, 0.12), vec3(0.78, 0.50, 0.20), seam); ALBEDO = mix(plank, plank * 0.86, grain); }\n" + TOY_LIGHT
	var material := ShaderMaterial.new()
	material.shader = _wood_shader
	return material
