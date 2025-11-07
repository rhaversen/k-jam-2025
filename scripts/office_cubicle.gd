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
	var back_wall := MeshInstance3D.new()
	back_wall.mesh = BoxMesh.new()
	back_wall.mesh.size = Vector3(4.0, 2.0, 0.1)
	back_wall.material_override = wall_mat
	back_wall.position = Vector3(0, 0, -2.5)
	add_child(back_wall)

	# left wall
	var left_wall := MeshInstance3D.new()
	left_wall.mesh = BoxMesh.new()
	left_wall.mesh.size = Vector3(0.1, 2.0, 3.5)
	left_wall.material_override = wall_mat
	left_wall.position = Vector3(-2.0, 0, -1.0)
	add_child(left_wall)

	# right wall
	var right_wall := left_wall.duplicate()
	right_wall.position.x = 2.0
	add_child(right_wall)

	# ----- DESK -----
	var desk := Node3D.new()
	desk.name = "Desk"
	add_child(desk)

	var desk_top := MeshInstance3D.new()
	desk_top.mesh = BoxMesh.new()
	desk_top.mesh.size = Vector3(2.2, 0.1, 1.0)
	var desk_mat := StandardMaterial3D.new()
	desk_mat.albedo_color = Color(0.55, 0.45, 0.35) # wooden top
	desk_mat.roughness = 0.6
	desk_top.material_override = desk_mat
	desk_top.position = Vector3(0, -0.5, -1.8)
	desk.add_child(desk_top)

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
	handle_top.position = Vector3(0.12, 0.1, 0.05)
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
	handle_mid.position = Vector3(0.14, 0.07, 0.05)
	mug.add_child(handle_mid)

	# Bottom segment
	var handle_bottom := MeshInstance3D.new()
	var mesh_bottom := CylinderMesh.new()
	mesh_bottom.top_radius = 0.02
	mesh_bottom.bottom_radius = 0.02
	mesh_bottom.height = 0.06
	handle_bottom.mesh = mesh_bottom
	handle_bottom.material_override = handle_mat
	handle_bottom.rotation_degrees = Vector3(0, 0, 90)
	handle_bottom.position = Vector3(0.12, -0.02, -0.03)
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

	# ----- CHAIR -----
	var chair := MeshInstance3D.new()
	chair.mesh = BoxMesh.new()
	chair.mesh.size = Vector3(0.6, 0.1, 0.6)
	var chair_mat := StandardMaterial3D.new()
	chair_mat.albedo_color = Color(0.15, 0.15, 0.18)
	chair.material_override = chair_mat
	chair.position = Vector3(0, -0.95, 0.0)
	add_child(chair)

	# ----- CAMERA (PLAYER VIEW) -----
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	cam.current = true
	cam.position = Vector3(0, 0.9, 0.4)
	add_child(cam)

	print("✅ Office cubicle generated successfully.")
