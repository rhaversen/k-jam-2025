extends Node3D
# Builds a simple, clean office cubicle scene (Godot 4.5.1)
# Static environment – no movement or particle effects.

func _ready() -> void:
	# ----- ENVIRONMENT -----
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.ambient_light_color = Color(1, 1, 1)
	environment.ambient_light_energy = 1.0
	env.environment = environment
	add_child(env)

	# ----- MAIN LIGHT -----
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-60, 30, 0)
	light.light_color = Color(0.95, 0.97, 1.0) # fluorescent white
	light.light_energy = 1.3
	light.shadow_enabled = true
	add_child(light)

	# ----- FLOOR -----
	var floor := MeshInstance3D.new()
	floor.mesh = PlaneMesh.new()
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.25, 0.28, 0.3) # grey carpet
	floor_mat.roughness = 1.0
	floor.material_override = floor_mat
	floor.position.y = -1.0
	add_child(floor)

	# ----- CUBICLE WALLS -----
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.85, 0.85, 0.9) # light fabric panels
	wall_mat.roughness = 0.8

	# back wall
	var back_wall := _create_static_mesh_body(self, Vector3(4.0, 2.0, 0.1), wall_mat, Vector3(0, 0, -2.5))
	back_wall.name = "BackWall"

	# left wall
	var left_wall := _create_static_mesh_body(self, Vector3(0.1, 2.0, 3.5), wall_mat, Vector3(-2.0, 0, -1.0))
	left_wall.name = "LeftWall"

	# right wall
	var right_wall := _create_static_mesh_body(self, Vector3(0.1, 2.0, 3.5), wall_mat, Vector3(2.0, 0, -1.0))
	right_wall.name = "RightWall"

	# ----- DESK -----
	var desk := Node3D.new()
	desk.name = "Desk"
	add_child(desk)

	var desk_mat := StandardMaterial3D.new()
	desk_mat.albedo_color = Color(0.55, 0.45, 0.35) # wooden top
	desk_mat.roughness = 0.6
	var desk_top := _create_static_mesh_body(desk, Vector3(2.2, 0.1, 1.0), desk_mat, Vector3(0, -0.5, -1.8))
	desk_top.name = "DeskTop"

	   # ----- MONITOR -----
	var stand_mat := StandardMaterial3D.new()
	stand_mat.albedo_color = Color(0.05, 0.05, 0.05)
	stand_mat.roughness = 0.8

	# Base disc (smaller + clearly above desk)
	var base_disc := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 0.25
	base_mesh.bottom_radius = 0.25
	base_mesh.height = 0.03
	base_disc.mesh = base_mesh
	base_disc.material_override = stand_mat
	base_disc.position = Vector3(0, -0.44, -2.05)   # slightly higher & back
	desk.add_child(base_disc)

	# Stand neck (now above the base and behind the screen)
	var neck := MeshInstance3D.new()
	neck.mesh = BoxMesh.new()
	neck.mesh.size = Vector3(0.08, 0.28, 0.08)
	neck.material_override = stand_mat
	neck.position = Vector3(0, -0.29, -2.05)        # moved slightly back
	desk.add_child(neck)

	# Monitor body (raised slightly so it sits on top of neck)
	var monitor_body := MeshInstance3D.new()
	monitor_body.mesh = BoxMesh.new()
	monitor_body.mesh.size = Vector3(1.0, 0.6, 0.05)
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.05, 0.05, 0.05)
	body_mat.roughness = 0.9
	monitor_body.material_override = body_mat
	monitor_body.position = Vector3(0, -0.02, -2.0)  # lifted up a little
	monitor_body.rotation_degrees = Vector3(0, 180, 0)
	desk.add_child(monitor_body)

	# Screen (flush in front of frame)
	var screen := MeshInstance3D.new()
	screen.mesh = BoxMesh.new()
	screen.mesh.size = Vector3(0.9, 0.5, 0.01)
	var screen_mat := StandardMaterial3D.new()
	screen_mat.albedo_color = Color(0.05, 0.1, 0.08)
	screen_mat.emission_enabled = true
	screen_mat.emission = Color(0.1, 0.8, 0.6)
	screen_mat.emission_energy_multiplier = 1.8
	screen.material_override = screen_mat
	screen.position = Vector3(0, 0, -0.03)
	monitor_body.add_child(screen)

	# Subtle glow in front of screen
	var screen_light := OmniLight3D.new()
	screen_light.light_energy = 1.1
	screen_light.omni_range = 2.5
	screen_light.position = Vector3(0, 0.0, 0.25)
	screen.add_child(screen_light)

			# ----- MOUSE -----
	var mouse := MeshInstance3D.new()
	var mouse_mesh := BoxMesh.new()
	mouse_mesh.size = Vector3(0.1, 0.04, 0.15)  # width, height, depth
	mouse.mesh = mouse_mesh

	var mouse_mat := StandardMaterial3D.new()
	mouse_mat.albedo_color = Color(0.3, 0.3, 0.3)  # ✅ lighter gray body
	mouse_mat.roughness = 0.6
	mouse_mat.metallic = 0.05
	mouse.material_override = mouse_mat

	# Flat on desk, left of mug
	mouse.position = Vector3(0.45, -0.40, -1.55)
	desk.add_child(mouse)

	# Mouse line (darker divider)
	var mouse_line := MeshInstance3D.new()
	var line_mesh := BoxMesh.new()
	line_mesh.size = Vector3(0.01, 0.002, 0.09)
	mouse_line.mesh = line_mesh

	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.05, 0.05, 0.05)  # ✅ darker groove
	line_mat.roughness = 0.7
	mouse_line.material_override = line_mat

	mouse_line.position = Vector3(0, 0.022, -0.04)
	mouse.add_child(mouse_line)

	# ----- COFFEE MUG -----
	var mug := MeshInstance3D.new()
	var mug_mesh := CylinderMesh.new()
	mug_mesh.top_radius = 0.1
	mug_mesh.bottom_radius = 0.1
	mug_mesh.height = 0.25
	mug.mesh = mug_mesh

	var mug_mat := StandardMaterial3D.new()
	mug_mat.albedo_color = Color(0.9, 0.9, 0.9)  # white ceramic
	mug_mat.roughness = 0.3
	mug.material_override = mug_mat

	mug.position = Vector3(0.8, -0.42, -1.55)
	desk.add_child(mug)

	# ----- MUG HANDLE (C-shaped, attached to mug) -----
	var handle_mat := mug_mat  # reuse mug material

	# Top segment
	var handle_top := MeshInstance3D.new()
	var mesh_top := CylinderMesh.new()
	mesh_top.top_radius = 0.02
	mesh_top.bottom_radius = 0.02
	mesh_top.height = 0.06
	handle_top.mesh = mesh_top
	handle_top.material_override = handle_mat
	handle_top.rotation_degrees = Vector3(0, 0, 90)
	handle_top.position = Vector3(0.12, 0.1, 0.0)
	mug.add_child(handle_top)

	# Middle segment
	var handle_mid := MeshInstance3D.new()
	var mesh_mid := CylinderMesh.new()
	mesh_mid.top_radius = 0.02
	mesh_mid.bottom_radius = 0.02
	mesh_mid.height = 0.08
	handle_mid.mesh = mesh_mid
	handle_mid.material_override = handle_mat
	handle_mid.rotation_degrees = Vector3(0, 0, 0)
	handle_mid.position = Vector3(0.14, 0.07, 0.0)
	mug.add_child(handle_mid)

	# Bottom segments
	var handle_bottom := MeshInstance3D.new()
	var mesh_bottom := CylinderMesh.new()
	mesh_bottom.top_radius = 0.02
	mesh_bottom.bottom_radius = 0.02
	mesh_bottom.height = 0.06
	handle_bottom.mesh = mesh_bottom
	handle_bottom.material_override = handle_mat
	handle_bottom.rotation_degrees = Vector3(0, 0, 90)
	handle_bottom.position = Vector3(0.12, 0.02, 0.0)
	mug.add_child(handle_bottom)

	# ----- COFFEE SURFACE -----
	var coffee_surface := MeshInstance3D.new()
	var coffee_mesh := CylinderMesh.new()
	coffee_mesh.top_radius = 0.075  # smaller radius for visible rim
	coffee_mesh.bottom_radius = 0.075
	coffee_mesh.height = 0.001  # flat disc
	coffee_surface.mesh = coffee_mesh

	var coffee_mat := StandardMaterial3D.new()
	coffee_mat.albedo_color = Color(0.25, 0.12, 0.05)  # coffee brown
	coffee_mat.roughness = 0.4
	coffee_surface.material_override = coffee_mat

	coffee_surface.position = Vector3(0.0, 0.125, 0.0)  # just below mug rim
	mug.add_child(coffee_surface)


	
		# ----- KEYBOARD -----
	var keyboard_base := MeshInstance3D.new()
	var kb_mesh := BoxMesh.new()
	kb_mesh.size = Vector3(0.7, 0.05, 0.28)  # longer base stays
	keyboard_base.mesh = kb_mesh

	var kb_mat := StandardMaterial3D.new()
	kb_mat.albedo_color = Color(0.3, 0.3, 0.3)  # same as mouse body
	kb_mat.roughness = 0.6
	kb_mat.metallic = 0.05
	keyboard_base.material_override = kb_mat

	keyboard_base.position = Vector3(-0.05, -0.43, -1.55)  # close to mouse
	desk.add_child(keyboard_base)

	# Create rows of keycaps
	var key_mat := StandardMaterial3D.new()
	key_mat.albedo_color = Color(0.05, 0.05, 0.05)  # darker keycaps
	key_mat.roughness = 0.8

	var key_size := Vector3(0.05, 0.02, 0.05)
	var start_x := -0.35
	var start_z := -1.43

	for row in range(4):  # ✅ reduced to 4 rows
		for col in range(11):  # ✅ keep 11 columns
			var key := MeshInstance3D.new()
			var key_mesh := BoxMesh.new()
			key_mesh.size = key_size
			key.mesh = key_mesh
			key.material_override = key_mat

			var x := start_x + col * 0.06
			var y := -0.40
			var z := start_z - row * 0.06
			key.position = Vector3(x, y, z)
			desk.add_child(key)

	# Posters
	_add_posters()


# ------------------------------------------------------------
# HELPER FUNCTIONS  (these go AFTER _ready(), not indented)
# ------------------------------------------------------------

func make_poster_material(texture_path: String, poster_size) -> StandardMaterial3D:
	var tex := load(texture_path)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex

	# Figure out the poster's width/height regardless of Vector2 or Vector3
	var poster_w: float = 1.0
	var poster_h: float = 1.0
	if poster_size is Vector2:
		poster_w = poster_size.x
		poster_h = poster_size.y
	elif poster_size is Vector3:
		poster_w = poster_size.x
		poster_h = poster_size.y

	if tex is Texture2D and poster_h != 0.0:
		var img_size = tex.get_size()
		var img_aspect: float = float(img_size.x) / float(img_size.y)
		var poster_aspect: float = poster_w / poster_h

		# Scale to preserve image aspect on the poster
		var scale_x := 1.0
		var scale_y := 1.0
		if img_aspect > poster_aspect:
			# image is wider -> letterbox vertically
			scale_x = poster_aspect / img_aspect
		else:
			# image is taller -> letterbox horizontally
			scale_y = img_aspect / poster_aspect

		mat.uv1_scale = Vector3(scale_x, scale_y, 1.0)
		# Center the image so the “letterbox” is even on both sides
		mat.uv1_offset = Vector3((1.0 - scale_x) * 0.5, (1.0 - scale_y) * 0.5, 0.0)
	else:
		mat.uv1_scale = Vector3(1.0, 1.0, 1.0)
		mat.uv1_offset = Vector3(0.0, 0.0, 0.0)

	# Optional general look
	mat.roughness = 0.4
	mat.albedo_color = Color(1, 1, 1)
	return mat

func _add_posters() -> void:
	# ----- Left poster (auto-size from texture aspect) -----
	var poster_back_left := MeshInstance3D.new()
	var poster_mesh_left := PlaneMesh.new()
	var tex_left := load("res://textures/poster1.png")
	var target_h := 0.8
	var size_left := Vector2(1.0, 0.7)
	if tex_left is Texture2D and target_h > 0.0:
		var img_size_left := (tex_left as Texture2D).get_size()
		if img_size_left.y != 0:
			var aspect_left := float(img_size_left.x) / float(img_size_left.y)
			size_left = Vector2(aspect_left * target_h, target_h)
	poster_mesh_left.size = size_left
	poster_back_left.mesh = poster_mesh_left
	poster_back_left.material_override = make_poster_material("res://textures/poster1.png", poster_mesh_left.size)
	poster_back_left.position = Vector3(-0.8, 0.4, -2.445)
	poster_back_left.rotation_degrees = Vector3(90, 0, 0)
	add_child(poster_back_left)

	# ----- Right poster (auto-size from texture aspect) -----
	var poster_back_right := MeshInstance3D.new()
	var poster_mesh_right := PlaneMesh.new()
	var tex_right := load("res://textures/poster2.png")
	var size_right := Vector2(1.0, 0.7)
	if tex_right is Texture2D and target_h > 0.0:
		var img_size_right := (tex_right as Texture2D).get_size()
		if img_size_right.y != 0:
			var aspect_right := float(img_size_right.x) / float(img_size_right.y)
			size_right = Vector2(aspect_right * target_h, target_h)
	poster_mesh_right.size = size_right
	poster_back_right.mesh = poster_mesh_right
	poster_back_right.material_override = make_poster_material("res://textures/poster2.png", poster_mesh_right.size)
	poster_back_right.position = Vector3(0.8, 0.4, -2.445)
	poster_back_right.rotation_degrees = Vector3(90, 0, 0)
	add_child(poster_back_right)


	## ----- CHAIR -----
	#var chair := MeshInstance3D.new()
	#chair.mesh = BoxMesh.new()
	#chair.mesh.size = Vector3(0.6, 0.1, 0.6)
	#var chair_mat := StandardMaterial3D.new()
	#chair_mat.albedo_color = Color(0.15, 0.15, 0.18)
	#chair.material_override = chair_mat
	#chair.position = Vector3(0, -0.95, 0.0)
	#add_child(chair)

	## ----- CAMERA (PLAYER VIEW) -----
	#var cam := Camera3D.new()
	#cam.name = "Camera3D"
	#cam.current = true
	#cam.position = Vector3(0, 0.9, 0.4)
	#add_child(cam)

	print("✅ Office cubicle generated successfully.")


func _create_static_mesh_body(parent: Node3D, size: Vector3, material: StandardMaterial3D, position: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = position
	parent.add_child(body)

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	if material:
		mesh_instance.material_override = material
	body.add_child(mesh_instance)

	var collision_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision_shape.shape = shape
	body.add_child(collision_shape)

	return body
