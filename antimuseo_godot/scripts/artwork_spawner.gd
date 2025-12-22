extends Node3D

@export var artwork_scene: PackedScene
@export var images_path: String = "res://assets/ASASDADA"

var image_files: Array[String] = []
var floating_artworks: Array[Node] = []

# Escalas para variedad visual
enum ArtworkSize { SMALL, MEDIUM, LARGE, MONUMENTAL }
var size_scales = {
	ArtworkSize.SMALL: 0.7,
	ArtworkSize.MEDIUM: 1.0,
	ArtworkSize.LARGE: 1.5,
	ArtworkSize.MONUMENTAL: 2.5
}

func _ready():
	# Crear un piso para evitar que el jugador caiga al vacío
	var ground = StaticBody3D.new()
	var mesh_instance = MeshInstance3D.new()
	var collision_shape = CollisionShape3D.new()

	mesh_instance.mesh = PlaneMesh.new()
	mesh_instance.mesh.size = Vector2(100, 100)

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.2, 0.2)  # Gris oscuro para el piso
	mesh_instance.material_override = material

	collision_shape.shape = BoxShape3D.new()
	collision_shape.shape.size = Vector3(100, 0.1, 100)

	ground.add_child(mesh_instance)
	ground.add_child(collision_shape)
	ground.position.y = -1.0  # Más bajo para que la dragona esté completamente sobre el suelo
	add_child(ground)
	
	# Load image list from descriptions JSON (manifest) instead of DirAccess
	# which is unreliable in web exports.
	var json_path = "res://artwork_descriptions.json"
	if FileAccess.file_exists(json_path):
		var file = FileAccess.open(json_path, FileAccess.READ)
		var json = JSON.new()
		json.parse(file.get_as_text())
		var data = json.get_data()
		if data is Dictionary:
			for key in data.keys():
				image_files.append(images_path + "/" + key)
			print("Loaded ", image_files.size(), " images from manifest.")
	
	# Fallback if JSON fails or is missing, try DirAccess (local dev)
	if image_files.is_empty():
		var dir = DirAccess.open(images_path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir() and (file_name.ends_with(".jpg") or file_name.ends_with(".png") or file_name.ends_with(".jpeg") or file_name.ends_with(".import")):
					var clean_name = file_name.replace(".import", "")
					if not image_files.has(images_path + "/" + clean_name):
						image_files.append(images_path + "/" + clean_name)
				file_name = dir.get_next()
			dir.list_dir_end()
	
	# Spawn one artwork per image, up to available
	for i in range(image_files.size()):
		var artwork = artwork_scene.instantiate()
		artwork.set_texture_path(image_files[i])
		
		# Asignar tamaño variado (distribución: 40% medium, 30% large, 20% small, 10% monumental)
		var random_size = randf()
		var size: ArtworkSize
		if random_size < 0.2:
			size = ArtworkSize.SMALL
		elif random_size < 0.6:
			size = ArtworkSize.MEDIUM
		elif random_size < 0.9:
			size = ArtworkSize.LARGE
		else:
			size = ArtworkSize.MONUMENTAL
		
		var scale_factor = size_scales[size]
		artwork.scale = Vector3(scale_factor, scale_factor, scale_factor)
		
		# Posicionar con más espacio vertical y evitar el centro (Dragona)
		var height = randf_range(3, 15) if size == ArtworkSize.MONUMENTAL else randf_range(2, 10)
		
		# Generar posición evitando radio central de 8 unidades
		var pos_ok = false
		var spawn_pos = Vector3()
		var attempts = 0
		while !pos_ok and attempts < 10:
			spawn_pos = Vector3(randf_range(-35, 35), height, randf_range(-35, 35))
			if Vector2(spawn_pos.x, spawn_pos.z).length() > 8.0:
				pos_ok = true
			attempts += 1
			
		artwork.position = spawn_pos
		artwork.rotation.y = randf() * TAU  # Random rotation for surreal effect
		artwork.add_to_group("artwork")
		add_child(artwork)
		floating_artworks.append(artwork)
	
	if image_files.is_empty():
		print("Warning: No images found in " + images_path + ". Spawning placeholders.")
		for i in range(10):
			var artwork = artwork_scene.instantiate()
			artwork.position = Vector3(randf_range(-20, 20), randf_range(1, 5), randf_range(-20, 20))
			artwork.rotation.y = randf() * TAU
			add_child(artwork)
			floating_artworks.append(artwork)
	
	# Designar una obra aleatoria como objetivo del quest
	if not floating_artworks.is_empty():
		var quest_artwork = floating_artworks[randi() % floating_artworks.size()]
		if quest_artwork.has_method("set_quest_target"):
			quest_artwork.set_quest_target()
			print("Quest artwork set at: ", quest_artwork.position)

func _process(delta):
	# Make artworks float gently up and down
	for artwork in floating_artworks:
		if artwork != null:
			var float_offset = sin(Time.get_ticks_msec() / 1000.0 + artwork.position.x) * 0.5 * delta
			artwork.position.y += float_offset
			
			# Slowly rotate the artworks
			artwork.rotate_y(0.1 * delta)