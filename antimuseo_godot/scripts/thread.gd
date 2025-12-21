extends Node3D

var start_pos: Vector3
var end_pos: Vector3
var progress: float = 0.0
var speed: float = 0.5
var is_drawing: bool = false

# Removed @onready to avoid startup errors. We reference it directly or look it up.
var mesh_instance: MeshInstance3D

func _ready():
	setup_mesh()

func setup_mesh():
	# If it exists, remove it to start fresh
	if has_node("MeshInstance3D"):
		get_node("MeshInstance3D").queue_free()
	
	var mi = MeshInstance3D.new()
	mi.name = "MeshInstance3D"
	var mesh = ImmediateMesh.new()
	mi.mesh = mesh
	
	# Material for the thread
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.0, 0.0) # Red
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.0, 0.0)
	mat.emission_energy_multiplier = 2.0
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	# Disable point size to avoid "dots"
	mat.use_point_size = false
	# Enable cull mode disabled so the ribbon is visible from both sides
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	
	add_child(mi)
	mesh_instance = mi

func setup_thread(start: Vector3, end: Vector3):
	start_pos = start
	end_pos = end
	is_drawing = true
	progress = 0.0
	print("Hilo rojo iniciado desde ", start, " hasta ", end)
	# Ensure mesh is ready
	if not mesh_instance:
		setup_mesh()

func _process(delta):
	if is_drawing:
		progress += delta * 0.3 # Slow down slightly to 3.3 seconds
		if progress >= 1.0:
			progress = 1.0
			is_drawing = false
			print("Hilo rojo completado")
		
		update_thread_mesh()

func update_thread_mesh():
	if not mesh_instance or not mesh_instance.mesh:
		return
		
	var mesh = mesh_instance.mesh as ImmediateMesh
	mesh.clear_surfaces()
	# Use TRIANGLE_STRIP for a thick ribbon instead of a thin line
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	var points = 100
	var thickness = 0.05 # Thickness of the wool thread
	
	# Calculate a camera-facing up vector (simplified: just global UP for now, or cross prod relative to direction)
	var dir = (end_pos - start_pos).normalized()
	# Tangent to direction
	var side = dir.cross(Vector3.UP).normalized()
	if side.length_squared() < 0.01:
		side = Vector3(1, 0, 0)
		
	for i in range(points + 1):
		var t = float(i) / points
		if t > progress:
			break
		
		var p_center = start_pos.lerp(end_pos, t)
		
		# Add waviness for "wool" effect
		var wave1 = sin(t * 30.0) * 0.1
		var wave2 = cos(t * 25.0) * 0.1
		p_center.x += wave1
		p_center.y += wave2
		
		var p1 = p_center + (side * thickness)
		var p2 = p_center - (side * thickness)
		
		mesh.surface_add_vertex(p1)
		mesh.surface_add_vertex(p2)
	
	mesh.surface_end()
