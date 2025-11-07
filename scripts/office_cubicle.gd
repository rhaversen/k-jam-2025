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
	var monitor := MeshInstance3D.new()
	monitor.mesh = BoxMesh.new()
	monitor.mesh.size = Vector3(0.6, 0.4, 0.03)
	var mon_mat := StandardMaterial3D.new()
	mon_mat.albedo_color = Color(0.1, 0.1, 0.1)
	mon_mat.emission_enabled = true
	mon_mat.emission = Color(0.0, 1.0, 0.8)
	mon_mat.emission_energy_multiplier = 0.9
	monitor.material_override = mon_mat
	monitor.position = Vector3(0, -0.3, -2.25)
	desk.add_child(monitor)

	# monitor light
	var screen_light := OmniLight3D.new()
	screen_light.light_energy = 1.2
	screen_light.omni_range = 1.8
	screen_light.position = Vector3(0, 0.1, 0)
	monitor.add_child(screen_light)

	# ----- COFFEE MUG (STATIC) -----
	var mug := MeshInstance3D.new()
	var mug_mesh := CylinderMesh.new()
	mug_mesh.top_radius = 0.15
	mug_mesh.bottom_radius = 0.15
	mug_mesh.height = 0.25
	mug.mesh = mug_mesh
	var mug_mat := StandardMaterial3D.new()
	mug_mat.albedo_color = Color(1.0, 0.95, 0.9)
	mug.material_override = mug_mat
	mug.position = Vector3(0.6, -0.4, -1.5)
	desk.add_child(mug)

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
