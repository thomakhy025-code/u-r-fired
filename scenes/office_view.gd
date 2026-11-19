class_name OfficeView
extends Control

## Steep 3D toy office. Click people, the phone, the bench, and the supply shelf.
## The opening lesson draws an arrow over the view until the first deal pays.

const INK := Color("3a2c24")
const CREAM := Color("fff6e8")
const WOOD := Color("6b3e22")
const HONEY := Color("e0b56a")
const PEACH := Color("e7a07a")
const CORAL := Color("e06a58")
const CAMERA_ELEVATION := 75.0

var game: GameState
var world: Node3D
var camera: Camera3D
var viewport: SubViewport
var view_box: SubViewportContainer
var selected: String = ""
var phone_face_id: String = ""
var _time: float = 0.0

var _opaque_shader: Shader
var _floor_shader: Shader
var _rug_shader: Shader
var _glass_shader: Shader
var _colors: Dictionary[String, ShaderMaterial] = {}

var name_label: Label
var note_label: Label
var cash_label: Label
var skill_label: Label
var research_button: Button
var wood_plaque: Button
var plastic_plaque: Button
var glass_plaque: Button
var chair_plaque: Button
var phone_plaque: Button
var bench_plaque: Button
var phone_panel: PanelContainer
var phone_face: FaceBadge
var phone_name: Label
var phone_want: Label
var phone_love: Label
var phone_state: Label
var phone_quiet: Label
var love_track: ColorRect
var love_fill: ColorRect
var bench_panel: PanelContainer
var bench_status: Label
var chair_button: Button
var phone_button: Button
var shelf_panel: PanelContainer
var wood_button: Button
var plastic_button: Button
var glass_button: Button
var cards: Array[PlayerCard] = []
var card_ids: Array[String] = []

var phone_handset: MeshInstance3D
var phone_ring: MeshInstance3D
var bench_ring: MeshInstance3D
var shelf_ring: MeshInstance3D
var phone_name_label: Label3D
var love_label: Label3D
var craft_label: Label3D
var employee_ids: Array[String] = []
var employee_rings: Array[MeshInstance3D] = []
var phone_body: StaticBody3D
var bench_body: StaticBody3D
var shelf_body: StaticBody3D
var employee_bodies: Dictionary[String, StaticBody3D] = {}
var guide: LessonGuide
var lesson_seen_call: bool = false
var lesson_answered: bool = false


func bind(next: GameState) -> void:
	game = next


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_make_shaders()
	_build_world()
	_build_hud()
	if game != null:
		_build_actors()
	_build_guide()


func _process(delta: float) -> void:
	if game == null:
		return
	_time += delta
	_fit_viewport()
	_sync()
	_sync_lesson()
	_animate()


func _make_shaders() -> void:
	_opaque_shader = Shader.new()
	_opaque_shader.code = "shader_type spatial;\nrender_mode unshaded, cull_back;\nuniform vec4 albedo : source_color = vec4(0.72, 0.45, 0.28, 1.0);\nvoid fragment() {\n\tALBEDO = albedo.rgb;\n}\n"
	_floor_shader = Shader.new()
	_floor_shader.code = "shader_type spatial;\nrender_mode unshaded, cull_back;\nuniform vec4 color_a : source_color = vec4(0.77, 0.54, 0.29, 1.0);\nuniform vec4 color_b : source_color = vec4(0.68, 0.45, 0.22, 1.0);\nvoid fragment() {\n\tfloat band = mod(floor(UV.x * 14.0), 2.0);\n\tALBEDO = mix(color_a.rgb, color_b.rgb, band);\n}\n"
	_rug_shader = Shader.new()
	_rug_shader.code = "shader_type spatial;\nrender_mode unshaded, cull_back;\nuniform vec4 color_a : source_color = vec4(0.88, 0.48, 0.33, 1.0);\nuniform vec4 color_b : source_color = vec4(0.88, 0.71, 0.42, 1.0);\nvoid fragment() {\n\tvec2 cell = floor(UV * 8.0);\n\tfloat check = mod(cell.x + cell.y, 2.0);\n\tALBEDO = mix(color_a.rgb, color_b.rgb, check);\n}\n"
	_glass_shader = Shader.new()
	_glass_shader.code = "shader_type spatial;\nrender_mode unshaded, cull_back, blend_mix, depth_draw_always;\nuniform vec4 albedo : source_color = vec4(0.42, 0.66, 0.78, 0.42);\nvoid fragment() {\n\tALBEDO = albedo.rgb;\n\tALPHA = albedo.a;\n}\n"


func _mat(color: Color) -> ShaderMaterial:
	var key := color.to_html(false)
	if _colors.has(key):
		return _colors[key]
	var mat := ShaderMaterial.new()
	mat.shader = _opaque_shader
	mat.set_shader_parameter("albedo", color)
	_colors[key] = mat
	return mat


func _floor_mat() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = _floor_shader
	mat.set_shader_parameter("color_a", Color("c4894a"))
	mat.set_shader_parameter("color_b", Color("b67d3e"))
	return mat


func _rug_mat() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = _rug_shader
	mat.set_shader_parameter("color_a", Color("e07a55"))
	mat.set_shader_parameter("color_b", Color("e0b56a"))
	return mat


func _glass_mat() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = _glass_shader
	mat.set_shader_parameter("albedo", Color(0.42, 0.66, 0.78, 0.42))
	return mat


func _build_world() -> void:
	view_box = SubViewportContainer.new()
	view_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	view_box.stretch = true
	view_box.mouse_filter = Control.MOUSE_FILTER_STOP
	view_box.gui_input.connect(_on_view_input)
	add_child(view_box)
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.world_3d = World3D.new()
	viewport.size = Vector2i(1280, 720)
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.handle_input_locally = true
	viewport.physics_object_picking = false
	view_box.add_child(viewport)
	world = Node3D.new()
	viewport.add_child(world)
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("f3c1a4")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("f0c8a4")
	env.ambient_light_energy = 0.35
	env_node.environment = env
	world.add_child(env_node)
	camera = Camera3D.new()
	camera.fov = 48.0
	camera.near = 0.08
	camera.far = 80.0
	camera.current = true
	world.add_child(camera)
	_place_camera(Vector3(0.0, 0.65, 0.05))
	_build_room()


func _place_camera(target: Vector3) -> void:
	var elevation: float = deg_to_rad(CAMERA_ELEVATION)
	var distance: float = 12.2
	camera.position = target + Vector3(0.0, sin(elevation) * distance, cos(elevation) * distance)
	camera.look_at(target, Vector3.UP)


func _build_room() -> void:
	var floor_mesh := _add_box(world, Vector3(0.0, -0.1, -0.2), Vector3(16.4, 0.2, 12.2), Color("c4894a"))
	floor_mesh.material_override = _floor_mat()
	var rug := _add_box(world, Vector3(0.0, 0.02, -0.7), Vector3(10.2, 0.03, 3.6), Color("e07a55"))
	rug.material_override = _rug_mat()
	_add_box(world, Vector3(0.0, 1.45, -5.35), Vector3(16.2, 2.9, 0.24), PEACH)
	_add_box(world, Vector3(-8.05, 1.45, -0.2), Vector3(0.24, 2.9, 12.0), Color("e09670"))
	_add_box(world, Vector3(8.05, 1.45, -0.2), Vector3(0.24, 2.9, 12.0), Color("e09670"))
	_add_box(world, Vector3(0.0, 0.2, -5.16), Vector3(16.0, 0.28, 0.08), HONEY)
	_add_box(world, Vector3(-1.55, 2.05, -5.16), Vector3(0.1, 1.35, 0.08), WOOD)
	_add_box(world, Vector3(1.55, 2.05, -5.16), Vector3(0.1, 1.35, 0.08), WOOD)
	_add_box(world, Vector3(0.0, 2.68, -5.16), Vector3(3.2, 0.1, 0.08), WOOD)
	_add_box(world, Vector3(0.0, 1.42, -5.16), Vector3(3.2, 0.1, 0.08), WOOD)
	var glass := _add_box(world, Vector3(0.0, 2.05, -5.08), Vector3(2.9, 1.15, 0.04), Color("6aa8c4"))
	glass.material_override = _glass_mat()
	_plant(Vector3(-7.1, 0.0, -3.4))
	_plant(Vector3(7.1, 0.0, -3.2))


func _build_actors() -> void:
	var spots: Array[Vector3] = [
		Vector3(-3.15, 0.0, -0.85),
		Vector3(-1.05, 0.0, -0.85),
		Vector3(1.05, 0.0, -0.85),
		Vector3(3.15, 0.0, -0.85),
	]
	var index: int = 0
	while index < game.employees.size() and index < spots.size():
		var person: GameState.Employee = game.employees[index]
		_build_employee(person, spots[index])
		index += 1
	_build_phone(Vector3(-5.85, 0.0, 0.15))
	_build_bench(Vector3(0.0, 0.0, 1.15))
	_build_shelf(Vector3(5.85, 0.0, 0.15))


func _build_employee(person: GameState.Employee, pos: Vector3) -> void:
	var body := _station("employee", person.id, pos, Vector3(1.7, 1.9, 2.0), Vector3(0.0, 0.95, 0.25))
	employee_bodies[person.id] = body
	var ring := _add_box(body, Vector3(0.0, 0.05, 0.35), Vector3(1.55, 0.035, 1.7), Color("f0c36a"))
	ring.visible = false
	employee_rings.append(ring)
	employee_ids.append(person.id)
	_add_box(body, Vector3(0.0, 0.78, -0.15), Vector3(1.45, 0.1, 0.78), _desk_color(person.id))
	_add_box(body, Vector3(0.0, 0.58, 0.26), Vector3(1.45, 0.32, 0.08), _desk_color(person.id).darkened(0.12))
	var corners: Array[Vector3] = [
		Vector3(-0.6, 0.36, -0.42),
		Vector3(0.6, 0.36, -0.42),
		Vector3(-0.6, 0.36, 0.12),
		Vector3(0.6, 0.36, 0.12),
	]
	var corner_index: int = 0
	while corner_index < corners.size():
		_add_box(body, corners[corner_index], Vector3(0.09, 0.72, 0.09), WOOD)
		corner_index += 1
	_add_box(body, Vector3(0.15, 0.85, -0.12), Vector3(0.42, 0.02, 0.28), Color("f0d7b4"))
	_add_cylinder(body, Vector3(-0.48, 0.9, 0.05), 0.08, 0.14, CORAL)
	_add_capsule(body, Vector3(0.0, 0.5, 0.62), 0.18, 0.9, _shirt(person.id))
	_add_sphere(body, Vector3(0.0, 1.05, 0.7), 0.17, _skin(person.id))
	var hair := _add_sphere(body, Vector3(0.0, 1.16, 0.6), 0.17, _hair(person.id))
	hair.scale = Vector3(1.02, 0.55, 0.9)
	_add_sphere(body, Vector3(-0.055, 1.08, 0.84), 0.028, INK)
	_add_sphere(body, Vector3(0.055, 1.08, 0.84), 0.028, INK)
	_tag(body, person.display_name, Vector3(0.0, 1.48, 0.62), 36, CREAM)


func _build_phone(pos: Vector3) -> void:
	var body := _station("phone", "phone", pos, Vector3(1.7, 1.5, 1.5), Vector3(0.0, 0.75, 0.0))
	phone_body = body
	phone_ring = _add_box(body, Vector3(0.0, 0.045, 0.0), Vector3(1.45, 0.03, 1.15), Color("f0c36a"))
	phone_ring.visible = false
	_add_box(body, Vector3(0.0, 0.52, 0.0), Vector3(1.2, 0.1, 0.78), Color("c4894a"))
	_add_box(body, Vector3(-0.46, 0.26, -0.26), Vector3(0.1, 0.52, 0.1), WOOD)
	_add_box(body, Vector3(0.46, 0.26, -0.26), Vector3(0.1, 0.52, 0.1), WOOD)
	_add_box(body, Vector3(-0.46, 0.26, 0.26), Vector3(0.1, 0.52, 0.1), WOOD)
	_add_box(body, Vector3(0.46, 0.26, 0.26), Vector3(0.1, 0.52, 0.1), WOOD)
	_add_box(body, Vector3(0.0, 0.66, 0.0), Vector3(0.5, 0.12, 0.34), CORAL)
	phone_handset = _add_box(body, Vector3(0.0, 0.8, 0.0), Vector3(0.56, 0.08, 0.16), Color("c4512f"))
	phone_name_label = _tag(body, "Phone", Vector3(0.0, 1.12, 0.0), 44, CREAM)
	love_label = _tag(body, "5/5", Vector3(0.0, 1.55, 0.0), 58, Color("6b2a22"))
	love_label.visible = false


func _build_bench(pos: Vector3) -> void:
	var body := _station("bench", "bench", pos, Vector3(2.6, 1.4, 1.5), Vector3(0.0, 0.7, 0.0))
	bench_body = body
	bench_ring = _add_box(body, Vector3(0.0, 0.045, 0.0), Vector3(2.45, 0.03, 1.25), Color("f0c36a"))
	bench_ring.visible = false
	_add_box(body, Vector3(0.0, 0.74, 0.0), Vector3(2.3, 0.12, 1.05), Color("d08a45"))
	_add_box(body, Vector3(-1.0, 0.36, -0.38), Vector3(0.12, 0.72, 0.12), WOOD)
	_add_box(body, Vector3(1.0, 0.36, -0.38), Vector3(0.12, 0.72, 0.12), WOOD)
	_add_box(body, Vector3(-1.0, 0.36, 0.38), Vector3(0.12, 0.72, 0.12), WOOD)
	_add_box(body, Vector3(1.0, 0.36, 0.38), Vector3(0.12, 0.72, 0.12), WOOD)
	_add_box(body, Vector3(0.0, 0.86, 0.0), Vector3(0.7, 0.06, 0.42), Color("3d8ec4"))
	_add_box(body, Vector3(-0.62, 0.96, 0.05), Vector3(0.28, 0.22, 0.28), Color("3faf8a"))
	_add_box(body, Vector3(0.62, 0.94, 0.0), Vector3(0.16, 0.3, 0.08), Color("e07a6a"))
	_tag(body, "Bench", Vector3(0.0, 1.28, 0.0), 48, CREAM)
	craft_label = _tag(body, "", Vector3(0.0, 1.66, 0.0), 52, INK)
	craft_label.visible = false


func _build_shelf(pos: Vector3) -> void:
	var body := _station("shelf", "shelf", pos, Vector3(1.7, 2.3, 1.15), Vector3(0.0, 1.15, 0.0))
	shelf_body = body
	shelf_ring = _add_box(body, Vector3(0.0, 0.045, 0.15), Vector3(1.55, 0.03, 1.05), Color("f0c36a"))
	shelf_ring.visible = false
	_add_box(body, Vector3(0.0, 1.05, -0.28), Vector3(1.4, 2.1, 0.1), WOOD)
	_add_box(body, Vector3(-0.66, 1.05, 0.0), Vector3(0.08, 2.1, 0.48), Color("8d5a32"))
	_add_box(body, Vector3(0.66, 1.05, 0.0), Vector3(0.08, 2.1, 0.48), Color("8d5a32"))
	_add_box(body, Vector3(0.0, 0.48, 0.0), Vector3(1.28, 0.08, 0.46), Color("a56b3c"))
	_add_box(body, Vector3(0.0, 1.08, 0.0), Vector3(1.28, 0.08, 0.46), Color("a56b3c"))
	_add_box(body, Vector3(0.0, 1.68, 0.0), Vector3(1.28, 0.08, 0.46), Color("a56b3c"))
	_add_box(body, Vector3(0.0, 0.68, 0.02), Vector3(0.42, 0.28, 0.32), Color("c4894a"))
	_add_box(body, Vector3(0.0, 1.28, 0.02), Vector3(0.42, 0.28, 0.32), Color("6f93b0"))
	_add_box(body, Vector3(0.0, 1.88, 0.02), Vector3(0.42, 0.28, 0.32), Color("6aa8a0"))
	_tag(body, "Shelf", Vector3(0.0, 1.55, 0.42), 46, CREAM)


func _station(kind: String, id: String, pos: Vector3, shape_size: Vector3, shape_pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.set_meta("kind", kind)
	body.set_meta("id", id)
	body.collision_layer = 1
	body.collision_mask = 1
	var shape_node := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = shape_size
	shape_node.shape = box
	shape_node.position = shape_pos
	body.add_child(shape_node)
	world.add_child(body)
	return body


func _add_box(parent: Node3D, pos: Vector3, extents: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = extents
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.material_override = _mat(color)
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh_instance)
	return mesh_instance


func _add_sphere(parent: Node3D, pos: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.material_override = _mat(color)
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh_instance)
	return mesh_instance


func _add_capsule(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.material_override = _mat(color)
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh_instance)
	return mesh_instance


func _add_cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.material_override = _mat(color)
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh_instance)
	return mesh_instance


func _plant(pos: Vector3) -> void:
	_add_box(world, pos + Vector3(0.0, 0.18, 0.0), Vector3(0.36, 0.32, 0.36), Color("c4512f"))
	_add_sphere(world, pos + Vector3(0.0, 0.58, 0.0), 0.32, Color("2f8f45"))


func _tag(parent: Node3D, text: String, pos: Vector3, font_size: int, ink: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	var fallback: Font = ThemeDB.fallback_font
	if fallback != null:
		label.font = fallback
	label.font_size = font_size
	label.pixel_size = 0.0045
	label.outline_size = 10
	label.modulate = ink
	label.outline_modulate = Color("3a2c24")
	if ink == INK or ink == Color("6b2a22"):
		label.outline_modulate = CREAM
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = pos
	label.double_sided = true
	parent.add_child(label)
	return label


func _build_hud() -> void:
	var hud := Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 14
	root.offset_top = 10
	root.offset_right = -14
	root.offset_bottom = -8
	root.add_theme_constant_override("separation", 6)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(root)
	root.add_child(_header())
	note_label = _label("The phone will ring.", 18, INK)
	note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(note_label)
	root.add_child(_stock_row())
	root.add_child(_phone_bar())
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(spacer)
	bench_panel = _action_panel("Workbench")
	var bench_box: VBoxContainer = bench_panel.get_child(0) as VBoxContainer
	bench_status = _label("Pick a chair or a phone.", 16, INK)
	bench_box.add_child(bench_status)
	chair_button = _button("Chair", Color("3faf8a"), INK)
	chair_button.custom_minimum_size = Vector2(320, 42)
	chair_button.pressed.connect(_on_craft_pressed.bind("chair"))
	bench_box.add_child(chair_button)
	phone_button = _button("Phone", Color("e07a6a"), INK)
	phone_button.custom_minimum_size = Vector2(320, 42)
	phone_button.pressed.connect(_on_craft_pressed.bind("phone"))
	bench_box.add_child(phone_button)
	bench_panel.visible = false
	root.add_child(bench_panel)
	shelf_panel = _action_panel("Supply shelf")
	var shelf_box: VBoxContainer = shelf_panel.get_child(0) as VBoxContainer
	var shelf_hint := _label("Packs arrive on the shelf.", 16, INK)
	shelf_box.add_child(shelf_hint)
	wood_button = _button("Wood", Color("c4894a"), INK)
	wood_button.custom_minimum_size = Vector2(320, 40)
	wood_button.pressed.connect(_on_buy_pressed.bind("wood"))
	shelf_box.add_child(wood_button)
	plastic_button = _button("Plastic", Color("6f93b0"), INK)
	plastic_button.custom_minimum_size = Vector2(320, 40)
	plastic_button.pressed.connect(_on_buy_pressed.bind("plastic"))
	shelf_box.add_child(plastic_button)
	glass_button = _button("Glass", Color("6aa8a0"), INK)
	glass_button.custom_minimum_size = Vector2(320, 40)
	glass_button.pressed.connect(_on_buy_pressed.bind("glass"))
	shelf_box.add_child(glass_button)
	shelf_panel.visible = false
	root.add_child(shelf_panel)
	root.add_child(_card_row())


func _header() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label = _label("Company", 26, INK)
	row.add_child(name_label)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(gap)
	var cash_plaque := PanelContainer.new()
	cash_plaque.add_theme_stylebox_override("panel", _plate(HONEY, 12))
	cash_plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cash_label = _label("Cash 0", 24, INK)
	cash_plaque.add_child(cash_label)
	row.add_child(cash_plaque)
	skill_label = _label("Skill 1", 22, INK)
	skill_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(skill_label)
	research_button = _button("R&D", Color("f0b060"), INK)
	research_button.custom_minimum_size = Vector2(140, 46)
	research_button.pressed.connect(_on_research_pressed)
	row.add_child(research_button)
	return row


func _stock_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wood_plaque = _plaque("Wood  0", Color("c4894a"), "shelf")
	plastic_plaque = _plaque("Plastic  0", Color("6f93b0"), "shelf")
	glass_plaque = _plaque("Glass  0", Color("6aa8a0"), "shelf")
	chair_plaque = _plaque("Chairs  0", Color("3faf8a"), "bench")
	phone_plaque = _plaque("Phones  0", Color("e07a6a"), "bench")
	bench_plaque = _plaque("Bench free", HONEY, "bench")
	row.add_child(wood_plaque)
	row.add_child(plastic_plaque)
	row.add_child(glass_plaque)
	row.add_child(chair_plaque)
	row.add_child(phone_plaque)
	row.add_child(bench_plaque)
	return row


func _phone_bar() -> PanelContainer:
	phone_panel = PanelContainer.new()
	phone_panel.add_theme_stylebox_override("panel", _plate(Color("f0a598"), 16))
	phone_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	phone_panel.gui_input.connect(_on_phone_panel_input)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	phone_panel.add_child(row)
	phone_face = FaceBadge.for_id("nia")
	phone_face.custom_minimum_size = Vector2(48, 48)
	phone_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	phone_face.visible = false
	row.add_child(phone_face)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.add_theme_constant_override("separation", 0)
	row.add_child(words)
	phone_quiet = _label("The phone is quiet.", 18, INK)
	words.add_child(phone_quiet)
	phone_name = _label("", 18, INK)
	phone_name.visible = false
	words.add_child(phone_name)
	phone_want = _label("", 16, INK)
	phone_want.visible = false
	words.add_child(phone_want)
	var love_box := VBoxContainer.new()
	love_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	love_box.custom_minimum_size = Vector2(150, 0)
	row.add_child(love_box)
	phone_love = _label("Love 5/5", 28, INK)
	phone_love.visible = false
	love_box.add_child(phone_love)
	love_track = ColorRect.new()
	love_track.custom_minimum_size = Vector2(140, 14)
	love_track.color = INK
	love_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	love_track.visible = false
	love_box.add_child(love_track)
	love_fill = ColorRect.new()
	love_fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	love_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	love_fill.color = Color("2f7d46")
	love_track.add_child(love_fill)
	phone_state = _label("", 18, INK)
	phone_state.custom_minimum_size = Vector2(180, 0)
	phone_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	phone_state.visible = false
	row.add_child(phone_state)
	return phone_panel


func _card_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if game == null:
		return row
	var index: int = 0
	while index < game.employees.size():
		var person: GameState.Employee = game.employees[index]
		var card := PlayerCard.new()
		card.show_employee(person)
		card.gui_input.connect(_on_card_input.bind(person.id))
		row.add_child(card)
		cards.append(card)
		card_ids.append(person.id)
		index += 1
	return row


func _action_panel(title: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _plate(Color("f6ead8"), 16))
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(box)
	var heading := _label(title, 20, INK)
	box.add_child(heading)
	return panel


func _sync() -> void:
	if game.notice != "":
		note_label.text = game.notice
		game.notice = ""
	name_label.text = game.company_name
	cash_label.text = "Cash %d" % game.cash
	skill_label.text = "Skill %d" % game.skill
	if game.skill >= GameState.SKILL_MAX:
		research_button.text = "Skill %d" % game.skill
		research_button.disabled = true
	else:
		research_button.text = "R&D  %d" % game.research_cost()
		research_button.disabled = false
	wood_plaque.text = "Wood  %d" % game.material_qty("wood")
	plastic_plaque.text = "Plastic  %d" % game.material_qty("plastic")
	glass_plaque.text = "Glass  %d" % game.material_qty("glass")
	chair_plaque.text = "Chairs  %d" % game.goods_qty("chair")
	phone_plaque.text = "Phones  %d" % game.goods_qty("phone")
	if game.craft == null:
		bench_plaque.text = "Bench free"
	else:
		bench_plaque.text = "%s  %s" % [game.product_label(game.craft.product_id), game.clock_text(game.craft.seconds_left)]
	_sync_phone()
	_sync_actions()
	_sync_cards()
	_sync_rings()


func _sync_phone() -> void:
	var caller := game.caller
	var ringing := caller != null
	phone_quiet.visible = not ringing
	phone_face.visible = ringing
	phone_name.visible = ringing
	phone_want.visible = ringing
	phone_love.visible = ringing
	phone_state.visible = ringing
	love_track.visible = ringing
	if love_label != null:
		love_label.visible = ringing
	if phone_name_label != null:
		phone_name_label.visible = not ringing
	if not ringing:
		phone_face_id = ""
		return
	if phone_face_id != caller.face_id:
		phone_face_id = caller.face_id
		phone_face.apply_id(caller.face_id)
	phone_name.text = caller.display_name
	phone_want.text = "Wants %s." % game.product_phrase(caller.product_id, caller.qty)
	var love_line := "Love %s" % game.love_text(caller.love)
	phone_love.text = love_line
	if love_label != null:
		love_label.text = game.love_text(caller.love)
	var ratio := 0.0
	if GameState.LOVE_MAX > 0:
		ratio = clampf(caller.love / float(GameState.LOVE_MAX), 0.0, 1.0)
	phone_love.add_theme_color_override("font_color", Color("2f7d46").lerp(Color("c4473a"), 1.0 - ratio))
	love_fill.anchor_left = 0.0
	love_fill.anchor_top = 0.0
	love_fill.anchor_bottom = 1.0
	love_fill.offset_left = 0.0
	love_fill.offset_top = 0.0
	love_fill.offset_right = 0.0
	love_fill.offset_bottom = 0.0
	love_fill.anchor_right = ratio
	love_fill.color = Color("2f7d46").lerp(Color("c4473a"), 1.0 - ratio)
	if caller.phase == "talking":
		var person := game.find_employee(caller.employee_id)
		var who := "Someone"
		if person != null:
			who = person.display_name
		phone_state.text = "%s  %s" % [who, game.clock_text(caller.seconds_left)]
	else:
		phone_state.text = "Pick an employee."


func _sync_actions() -> void:
	bench_panel.visible = selected == "bench"
	shelf_panel.visible = selected == "shelf"
	var seconds := game.clock_text(game.craft_seconds())
	chair_button.text = "Chair   wood + plastic   %s" % seconds
	phone_button.text = "Phone   plastic + glass   %s" % seconds
	var busy := game.craft != null
	chair_button.disabled = busy
	phone_button.disabled = busy
	if game.craft == null:
		bench_status.text = "Pick a chair or a phone."
	else:
		bench_status.text = "%s  %s" % [game.product_label(game.craft.product_id), game.clock_text(game.craft.seconds_left)]
	wood_button.text = "Wood  %d for %d" % [GameState.PACK_QTY, game.pack_cost("wood")]
	plastic_button.text = "Plastic  %d for %d" % [GameState.PACK_QTY, game.pack_cost("plastic")]
	glass_button.text = "Glass  %d for %d" % [GameState.PACK_QTY, game.pack_cost("glass")]
	if craft_label != null:
		craft_label.visible = busy
		if busy:
			craft_label.text = game.clock_text(game.craft.seconds_left)


func _sync_cards() -> void:
	var index: int = 0
	while index < cards.size() and index < card_ids.size():
		var person := game.find_employee(card_ids[index])
		if person != null:
			cards[index].refresh(person)
			cards[index].set_hot(person.busy or selected == person.id)
		index += 1


func _sync_rings() -> void:
	if phone_ring != null:
		phone_ring.visible = selected == "phone" or game.caller != null
	if bench_ring != null:
		bench_ring.visible = selected == "bench" or game.craft != null
	if shelf_ring != null:
		shelf_ring.visible = selected == "shelf"
	var index: int = 0
	while index < employee_rings.size() and index < employee_ids.size():
		var person := game.find_employee(employee_ids[index])
		var show := false
		if person != null and (person.busy or selected == person.id):
			show = true
		employee_rings[index].visible = show
		index += 1


func _animate() -> void:
	if phone_handset == null:
		return
	var bob := 0.0
	if game.caller != null and game.caller.phase == "waiting":
		bob = sin(_time * 9.0) * 0.05
	phone_handset.position.y = 0.8 + bob


func _fit_viewport() -> void:
	if view_box == null or viewport == null:
		return
	var area := view_box.size
	if area.x < 32.0 or area.y < 32.0:
		return
	var next := Vector2i(maxi(int(area.x), 2), maxi(int(area.y), 2))
	if viewport.size != next:
		viewport.size = next


func _on_view_input(event: InputEvent) -> void:
	var mouse: InputEventMouseButton = event as InputEventMouseButton
	if mouse == null or not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	view_box.accept_event()
	_pick(_viewport_point(mouse.position))


func _viewport_point(local_pos: Vector2) -> Vector2:
	var area := view_box.size
	if area.x < 1.0 or area.y < 1.0:
		return local_pos
	return Vector2(local_pos.x * float(viewport.size.x) / area.x, local_pos.y * float(viewport.size.y) / area.y)


func _pick(screen_pos: Vector2) -> void:
	if camera == null or world == null:
		return
	var origin := camera.project_ray_origin(screen_pos)
	var target := origin + camera.project_ray_normal(screen_pos) * 80.0
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	var space := world.get_world_3d().direct_space_state
	if space == null:
		return
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		selected = ""
		return
	var collider: StaticBody3D = hit.get("collider") as StaticBody3D
	if collider == null or not collider.has_meta("kind"):
		selected = ""
		return
	var kind: String = str(collider.get_meta("kind"))
	var id: String = str(collider.get_meta("id"))
	if kind == "employee":
		_press_employee(id)
	elif kind == "phone" or kind == "bench" or kind == "shelf":
		_select_kind(kind)


func _on_phone_panel_input(event: InputEvent) -> void:
	var mouse: InputEventMouseButton = event as InputEventMouseButton
	if mouse == null or not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	phone_panel.accept_event()
	_select_kind("phone")


func _on_card_input(event: InputEvent, employee_id: String) -> void:
	var mouse: InputEventMouseButton = event as InputEventMouseButton
	if mouse == null or not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	_press_employee(employee_id)


func _press_employee(employee_id: String) -> void:
	selected = employee_id
	if game == null:
		return
	_say(game.assign_employee(employee_id))


func _select_kind(kind: String) -> void:
	if selected == kind:
		selected = ""
	else:
		selected = kind


func _on_craft_pressed(product_id: String) -> void:
	if game == null:
		return
	_say(game.start_craft(product_id))


func _on_buy_pressed(material_id: String) -> void:
	if game == null:
		return
	_say(game.buy_material(material_id))


func _on_research_pressed() -> void:
	if game == null:
		return
	_say(game.buy_research())


func _say(text: String) -> void:
	if note_label != null and text != "":
		note_label.text = text


func _desk_color(id: String) -> Color:
	match id:
		"mina":
			return Color("3faf8a")
		"june":
			return Color("3d8ec4")
		"otto":
			return Color("e09a3e")
		"rosa":
			return Color("b07cc4")
		_:
			return HONEY


func _shirt(id: String) -> Color:
	match id:
		"mina":
			return Color("2f7d72")
		"june":
			return Color("3d5a80")
		"otto":
			return Color("c46a32")
		"rosa":
			return Color("6e4d78")
		_:
			return Color("3d6e96")


func _skin(id: String) -> Color:
	match id:
		"mina":
			return Color("e2b896")
		"june":
			return Color("e8c4a8")
		"otto":
			return Color("dcb08a")
		"rosa":
			return Color("e0b090")
		_:
			return Color("e2b896")


func _hair(id: String) -> Color:
	match id:
		"mina":
			return Color("241c18")
		"june":
			return Color("6d4030")
		"otto":
			return Color("c4a060")
		"rosa":
			return Color("2a1814")
		_:
			return Color("241c18")


func _plaque(text: String, color: Color, kind: String) -> Button:
	var button := _button(text, color, INK)
	button.custom_minimum_size = Vector2(128, 46)
	button.pressed.connect(_select_kind.bind(kind))
	return button


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", ThemeDB.fallback_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text: String, color: Color, ink: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	_paint_button(button, color, ink)
	return button


func _paint_button(button: Button, color: Color, ink: Color) -> void:
	button.add_theme_font_override("font", ThemeDB.fallback_font)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", ink)
	button.add_theme_color_override("font_hover_color", ink)
	button.add_theme_color_override("font_pressed_color", ink)
	button.add_theme_color_override("font_disabled_color", Color("6d5848"))
	button.add_theme_stylebox_override("normal", _plate(color, 12))
	button.add_theme_stylebox_override("hover", _plate(color.lightened(0.06), 12))
	button.add_theme_stylebox_override("pressed", _plate(color.darkened(0.08), 12))
	button.add_theme_stylebox_override("focus", _plate(color.lightened(0.06), 12))
	button.add_theme_stylebox_override("disabled", _plate(color.darkened(0.18), 12))


func _plate(color: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = WOOD
	box.set_border_width_all(3)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box


enum LessonStep {
	WAIT_RING,
	SEE_CALL,
	SEND_EMPLOYEE,
	OPEN_SHELF,
	BUY_MATERIAL,
	OPEN_BENCH,
	START_CRAFT,
	WAIT_CRAFT,
	HAND_EMPLOYEE,
	HAND_CALL,
}


func _build_guide() -> void:
	guide = LessonGuide.new()
	guide.set_anchors_preset(Control.PRESET_FULL_RECT)
	guide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guide.z_index = 20
	guide.visible = false
	add_child(guide)


func _sync_lesson() -> void:
	if guide == null:
		return
	if game == null or not game.teaching or guide.size.x < 32.0 or guide.size.y < 32.0:
		guide.shown = false
		return
	_advance_lesson_flags()
	var step := _lesson_step()
	var point := _lesson_point(step)
	if point.x < -1000.0:
		guide.shown = false
		return
	var local_tip: Vector2 = guide.get_global_transform().affine_inverse() * point
	guide.tip = local_tip
	guide.message = _lesson_line(step)
	guide.shown = true


func _advance_lesson_flags() -> void:
	if game.caller == null:
		return
	if selected == "phone":
		lesson_seen_call = true
	if game.caller.phase == "talking":
		lesson_seen_call = true
		lesson_answered = true


func _lesson_step() -> LessonStep:
	if game.caller == null:
		return LessonStep.WAIT_RING
	var need_goods := game.goods_qty(game.caller.product_id) < game.caller.qty
	if not lesson_answered and game.caller.phase == "waiting" and not lesson_seen_call:
		return LessonStep.SEE_CALL
	if not lesson_answered and game.caller.phase == "waiting":
		return LessonStep.SEND_EMPLOYEE
	if need_goods:
		if game.craft != null:
			return LessonStep.WAIT_CRAFT
		if _needed_material() != "":
			if selected == "shelf":
				return LessonStep.BUY_MATERIAL
			return LessonStep.OPEN_SHELF
		if selected == "bench":
			return LessonStep.START_CRAFT
		return LessonStep.OPEN_BENCH
	if game.caller.phase == "waiting":
		return LessonStep.HAND_EMPLOYEE
	return LessonStep.HAND_CALL


func _lesson_point(step: LessonStep) -> Vector2:
	if step == LessonStep.WAIT_RING:
		return _phone_world_point()
	if step == LessonStep.SEE_CALL or step == LessonStep.HAND_CALL:
		return _control_point(phone_panel)
	if step == LessonStep.SEND_EMPLOYEE or step == LessonStep.HAND_EMPLOYEE:
		return _employee_point()
	if step == LessonStep.OPEN_SHELF:
		return _shelf_point()
	if step == LessonStep.BUY_MATERIAL:
		var bought := _control_point(_material_button(_needed_material()))
		if bought.x > -1000.0:
			return bought
		return _shelf_point()
	if step == LessonStep.START_CRAFT:
		var craft_point := _control_point(_product_button())
		if craft_point.x > -1000.0:
			return craft_point
		return _bench_point()
	if step == LessonStep.OPEN_BENCH or step == LessonStep.WAIT_CRAFT:
		return _bench_point()
	return Vector2(-10000.0, -10000.0)


func _lesson_line(step: LessonStep) -> String:
	var who := _lesson_who()
	var item := _lesson_item()
	var bundle := _lesson_bundle()
	var material := _material_word()
	var craft_name := "Chair"
	if game.caller != null:
		craft_name = game.product_label(game.caller.product_id)
	if step == LessonStep.WAIT_RING:
		return "Wait for the phone to ring."
	if step == LessonStep.SEE_CALL:
		return "Press the incoming call to meet the caller."
	if step == LessonStep.SEND_EMPLOYEE:
		return "Send %s to take the call." % who
	if step == LessonStep.OPEN_SHELF:
		return "Buy %s from the supply shelf." % material
	if step == LessonStep.BUY_MATERIAL:
		return "Buy a pack of %s." % material
	if step == LessonStep.OPEN_BENCH:
		return "Craft the %s on the workbench." % item
	if step == LessonStep.START_CRAFT:
		return "Press %s to craft it." % craft_name
	if step == LessonStep.WAIT_CRAFT:
		return "Wait for the %s to finish." % item
	if step == LessonStep.HAND_EMPLOYEE:
		return "Send %s to hand over %s." % [who, bundle]
	if step == LessonStep.HAND_CALL:
		return "%s hands %s to the caller." % [who, bundle]
	return "Wait for the phone to ring."


func _lesson_who() -> String:
	var person := _lesson_employee()
	if person == null:
		return "Someone"
	return _short_name(person.display_name)


func _lesson_employee() -> GameState.Employee:
	if game.caller != null and game.caller.employee_id != "":
		var current := game.find_employee(game.caller.employee_id)
		if current != null:
			return current
	var mina := game.find_employee("mina")
	if mina != null and not mina.busy:
		return mina
	var index: int = 0
	while index < game.employees.size():
		var person: GameState.Employee = game.employees[index]
		if not person.busy:
			return person
		index += 1
	if game.employees.is_empty():
		return null
	return game.employees[0]


func _short_name(display_name: String) -> String:
	var trimmed := display_name.strip_edges()
	var space := trimmed.find(" ")
	if space <= 0:
		return trimmed
	return trimmed.substr(0, space)


func _lesson_item() -> String:
	if game.caller == null:
		return "order"
	return game.product_name(game.caller.product_id)


func _lesson_bundle() -> String:
	if game.caller == null:
		return "the order"
	if game.caller.qty <= 1:
		return "the %s" % _lesson_item()
	return game.product_phrase(game.caller.product_id, game.caller.qty)


func _material_word() -> String:
	var material_id := _needed_material()
	if material_id == "":
		return "materials"
	return game.material_name(material_id).to_lower()


func _needed_material() -> String:
	if game == null or game.caller == null:
		return ""
	var index: int = 0
	while index < GameState.MATERIAL_ORDER.size():
		var material_id: String = GameState.MATERIAL_ORDER[index]
		if game.recipe_count(game.caller.product_id, material_id) > game.material_qty(material_id):
			return material_id
		index += 1
	return ""


func _phone_world_point() -> Vector2:
	var world_point := _body_point(phone_body, Vector3(0.0, 1.05, 0.0))
	if world_point.x > -1000.0 and not _covered_by_hud(world_point):
		return world_point
	return _control_point(phone_panel)


func _employee_point() -> Vector2:
	var person := _lesson_employee()
	if person == null:
		return Vector2(-10000.0, -10000.0)
	var world_point := _body_point(_employee_body(person.id), Vector3(0.0, 1.35, 0.7))
	if world_point.x > -1000.0 and not _covered_by_hud(world_point):
		return world_point
	return _card_point(person.id)


func _shelf_point() -> Vector2:
	var plaque := _control_point(_material_plaque(_needed_material()))
	if plaque.x > -1000.0:
		return plaque
	var world_point := _body_point(shelf_body, Vector3(0.0, 1.45, 0.2))
	if world_point.x > -1000.0 and not _covered_by_hud(world_point):
		return world_point
	return plaque


func _bench_point() -> Vector2:
	var world_point := _body_point(bench_body, Vector3(0.0, 1.2, 0.0))
	if world_point.x > -1000.0 and not _covered_by_hud(world_point):
		return world_point
	var plaque := _control_point(bench_plaque)
	if plaque.x > -1000.0:
		return plaque
	return _control_point(_product_plaque())


func _employee_body(employee_id: String) -> StaticBody3D:
	if employee_id == "" or not employee_bodies.has(employee_id):
		return null
	return employee_bodies[employee_id] as StaticBody3D


func _card_point(employee_id: String) -> Vector2:
	var index: int = 0
	while index < card_ids.size() and index < cards.size():
		if card_ids[index] == employee_id:
			return _control_point(cards[index])
		index += 1
	return Vector2(-10000.0, -10000.0)


func _material_plaque(material_id: String) -> Button:
	if material_id == "plastic":
		return plastic_plaque
	if material_id == "glass":
		return glass_plaque
	return wood_plaque


func _material_button(material_id: String) -> Button:
	if material_id == "plastic":
		return plastic_button
	if material_id == "glass":
		return glass_button
	return wood_button


func _product_plaque() -> Button:
	if game.caller != null and game.caller.product_id == "phone":
		return phone_plaque
	return chair_plaque


func _product_button() -> Button:
	if game.caller != null and game.caller.product_id == "phone":
		return phone_button
	return chair_button


func _covered_by_hud(point: Vector2) -> bool:
	if phone_panel != null and is_instance_valid(phone_panel) and phone_panel.is_visible_in_tree():
		var bar := phone_panel.get_global_rect()
		if point.y <= bar.end.y + 6.0:
			return true
	if _panel_covers(bench_panel, point):
		return true
	if _panel_covers(shelf_panel, point):
		return true
	var index: int = 0
	while index < cards.size():
		if _panel_covers(cards[index], point):
			return true
		index += 1
	return false


func _panel_covers(node: Control, point: Vector2) -> bool:
	if node == null or not is_instance_valid(node) or not node.is_visible_in_tree():
		return false
	return node.get_global_rect().grow(8.0).has_point(point)


func _control_point(node: Control) -> Vector2:
	if node == null or not is_instance_valid(node) or not node.is_visible_in_tree():
		return Vector2(-10000.0, -10000.0)
	var rect := node.get_global_rect()
	if rect.size.x < 2.0 or rect.size.y < 2.0:
		return Vector2(-10000.0, -10000.0)
	return _point_at_rect(rect)


func _point_at_rect(rect: Rect2) -> Vector2:
	var center := rect.get_center()
	if guide == null or guide.size.x < 32.0 or guide.size.y < 32.0:
		return center
	var screen_center: Vector2 = guide.get_global_transform() * (guide.size * 0.5)
	var toward := center - screen_center
	if toward.length() < 8.0:
		return Vector2(center.x, rect.position.y - 8.0)
	toward = toward.normalized()
	var half := rect.size * 0.5
	var reach_x := half.x / maxf(absf(toward.x), 0.05)
	var reach_y := half.y / maxf(absf(toward.y), 0.05)
	return center - toward * (minf(reach_x, reach_y) + 8.0)


func _body_point(body: Node3D, local_pos: Vector3) -> Vector2:
	if body == null or camera == null or view_box == null or viewport == null:
		return Vector2(-10000.0, -10000.0)
	var world_pos := body.to_global(local_pos)
	if camera.is_position_behind(world_pos):
		return Vector2(-10000.0, -10000.0)
	var projected := camera.unproject_position(world_pos)
	if is_nan(projected.x) or is_nan(projected.y) or is_inf(projected.x) or is_inf(projected.y):
		return Vector2(-10000.0, -10000.0)
	var vp_size := Vector2(viewport.size)
	var area := view_box.size
	if vp_size.x < 1.0 or vp_size.y < 1.0 or area.x < 1.0 or area.y < 1.0:
		return Vector2(-10000.0, -10000.0)
	var local := Vector2(projected.x * area.x / vp_size.x, projected.y * area.y / vp_size.y)
	if local.x < 16.0 or local.y < 16.0 or local.x > area.x - 16.0 or local.y > area.y - 16.0:
		return Vector2(-10000.0, -10000.0)
	return view_box.get_global_transform() * local


class LessonGuide extends Control:
	var message: String = ""
	var tip: Vector2 = Vector2.ZERO
	var shown: bool = false
	var tail: Vector2 = Vector2.ZERO
	var aim: Vector2 = Vector2.UP
	var line: Label
	var plate: PanelContainer

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("fff6e8")
		style.border_color = Color("6b3e22")
		style.set_border_width_all(3)
		style.set_corner_radius_all(12)
		style.content_margin_left = 14
		style.content_margin_right = 14
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		style.shadow_color = Color(0.23, 0.17, 0.14, 0.35)
		style.shadow_size = 6
		style.shadow_offset = Vector2(0, 3)
		plate = PanelContainer.new()
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.add_theme_stylebox_override("panel", style)
		add_child(plate)
		line = Label.new()
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		line.autowrap_mode = TextServer.AUTOWRAP_OFF
		var fallback: Font = ThemeDB.fallback_font
		if fallback != null:
			line.add_theme_font_override("font", fallback)
		line.add_theme_font_size_override("font_size", 20)
		line.add_theme_color_override("font_color", Color("3a2c24"))
		plate.add_child(line)
		visible = false

	func _process(_delta: float) -> void:
		visible = shown
		if not shown:
			return
		_refresh_aim()
		_place_line()
		queue_redraw()

	func _refresh_aim() -> void:
		var center := size * 0.5
		var delta := tip - center
		if delta.length() < 1.0:
			aim = Vector2(0.0, -1.0)
		else:
			aim = delta.normalized()
		var bob := sin(float(Time.get_ticks_msec()) * 0.006) * 10.0
		tail = tip - aim * (124.0 + bob)

	func _place_line() -> void:
		var font: Font = ThemeDB.fallback_font
		if font != null:
			line.add_theme_font_override("font", font)
		line.add_theme_font_size_override("font_size", 20)
		line.text = message
		var max_width := maxf(size.x - 48.0, 180.0)
		var text_size := Vector2(180.0, 26.0)
		if font != null:
			text_size = font.get_string_size(message, HORIZONTAL_ALIGNMENT_CENTER, -1, 20)
		if text_size.x > max_width and font != null:
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			text_size = font.get_string_size(message, HORIZONTAL_ALIGNMENT_CENTER, max_width, 20)
			text_size.x = max_width
		else:
			line.autowrap_mode = TextServer.AUTOWRAP_OFF
		var box_size := text_size + Vector2(28.0, 16.0)
		line.custom_minimum_size = text_size
		plate.custom_minimum_size = box_size
		plate.size = box_size
		var rest := tip - aim * 124.0
		var pos := rest - aim * (box_size.y * 0.5 + 16.0) - box_size * 0.5
		pos = _clamp_plate(pos, box_size)
		if Rect2(pos, box_size).grow(12.0).has_point(tip):
			var side := Vector2(-aim.y, aim.x)
			pos = _clamp_plate(pos + side * (box_size.y + 28.0), box_size)
		plate.position = pos
		plate.size = box_size

	func _clamp_plate(pos: Vector2, box_size: Vector2) -> Vector2:
		var margin_bottom := 120.0
		if size.y < 520.0:
			margin_bottom = 16.0
		var max_x := maxf(size.x - box_size.x - 12.0, 12.0)
		var max_y := maxf(size.y - box_size.y - margin_bottom, 12.0)
		pos.x = clampf(pos.x, 12.0, max_x)
		pos.y = clampf(pos.y, 12.0, max_y)
		return pos

	func _draw() -> void:
		if not shown:
			return
		_draw_arrow(tail + Vector2(3.0, 4.0), tip + Vector2(3.0, 4.0), Color(0.23, 0.17, 0.14, 0.28), 12.0, 34.0)
		_draw_arrow(tail, tip, Color("3a2c24"), 11.0, 32.0)
		_draw_arrow(tail, tip, Color("fff6e8"), 8.0, 26.0)
		_draw_arrow(tail, tip, Color("e06a58"), 5.0, 20.0)
		draw_circle(tail, 9.0, Color("3a2c24"))
		draw_circle(tail, 6.0, Color("fff6e8"))

	func _draw_arrow(from: Vector2, to: Vector2, fill: Color, width: float, head: float) -> void:
		var delta := to - from
		var length := delta.length()
		if length < 4.0:
			return
		var dir := delta / length
		var side := Vector2(-dir.y, dir.x)
		var neck := to - dir * head
		var shaft := PackedVector2Array()
		shaft.push_back(from + side * width)
		shaft.push_back(neck + side * width)
		shaft.push_back(neck - side * width)
		shaft.push_back(from - side * width)
		draw_colored_polygon(shaft, fill)
		var head_poly := PackedVector2Array()
		head_poly.push_back(to)
		head_poly.push_back(neck + side * head * 0.62)
		head_poly.push_back(neck - side * head * 0.62)
		draw_colored_polygon(head_poly, fill)
