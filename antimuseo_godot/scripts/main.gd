@icon("res://icon.png")

extends Node3D


@export var player_prefab: PackedScene
@export var artwork_scene: PackedScene
@export var dragona_scene: PackedScene
@export var thread_scene: PackedScene
@export var cape_character_scene: PackedScene

@onready var dialogue_ui = $CanvasLayer/DialogueUI
@onready var journal_ui = $CanvasLayer/Journal

@export var shadow_scene: PackedScene
var is_shadow_sequence_active = false

# Shadow Spawn Timing Variables
var min_spawn_interval = 3.0
var max_spawn_interval = 8.0
var shadow_spawn_timer = 0.0
var next_shadow_spawn_time = 0.0
var player = null

func _ready():
	Global.dialogue_ui = dialogue_ui
	
	# Encontrar el jugador
	await get_tree().create_timer(0.5).timeout
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	
	# Cargar shadow scene si no está asignada
	if shadow_scene == null:
		shadow_scene = load("res://shadow.tscn")
	# Thread scene loading
	if thread_scene == null:
		thread_scene = load("res://assets/thread.tscn")
	
	# Programar primer spawn
	schedule_next_shadow_spawn()

func _process(_delta):
	# Handle shadow spawning - DISABLED for narrative control
	# shadow_spawn_timer += delta
	# if shadow_spawn_timer >= next_shadow_spawn_time:
	# 	spawn_shadow()
	# 	schedule_next_shadow_spawn()
	pass

func schedule_next_shadow_spawn():
	next_shadow_spawn_time = randf_range(min_spawn_interval, max_spawn_interval)
	shadow_spawn_timer = 0.0

func spawn_shadow():
	if is_shadow_sequence_active:
		return
	is_shadow_sequence_active = true
	
	if shadow_scene == null:
		print("Shadow scene not loaded!")
		is_shadow_sequence_active = false
		return
		
	if player == null:
		print("Player not found!")
		is_shadow_sequence_active = false
		return
	
	# --- SECUENCIA DE SOMBRA ---
	print("🌑 INICIANDO SECUENCIA DE SOMBRA")
	
	# Limpiar diálogos previos para evitar saltos
	Global.hide_dialogue()
	
	# 1. Apagón (Oscuridad Total)
	var world_env = get_node_or_null("WorldEnvironment")
	var original_env = null
	
	if world_env:
		original_env = world_env.environment
		var dark_env = original_env.duplicate()
		dark_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		dark_env.ambient_light_color = Color.BLACK
		dark_env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
		world_env.environment = dark_env
	
	# Apagar luces direccionales temporalmente
	var lights = get_tree().get_nodes_in_group("lights")
	for light in lights:
		if light is Light3D:
			light.visible = false

	# Overlay negro (Simular ojos cerrados)
	var canvas = get_node_or_null("CanvasLayer")
	var overlay = null
	if canvas:
		overlay = ColorRect.new()
		overlay.name = "ShadowOverlay"
		overlay.color = Color.BLACK
		overlay.anchor_left = 0
		overlay.anchor_top = 0
		overlay.anchor_right = 1
		overlay.anchor_bottom = 1
		# CRÍTICO: No atrapar el mouse, dejar que el UI de diálogo funcione
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(overlay)

	# Small pause for the blackout to take effect
	await get_tree().create_timer(1.5).timeout
	
	# 2. Palabras Flotantes
	show_floating_words(player.global_position)
	await get_tree().create_timer(4.0).timeout
	
	# 3. Spawn Shadow y Diálogo
	var shadow_instance = shadow_scene.instantiate()
	if "suppress_dialogue" in shadow_instance:
		shadow_instance.suppress_dialogue = true
	
	add_child(shadow_instance)
	
	var player_pos = player.global_position
	var spawn_pos = player_pos + (player.global_transform.basis.z * -4.0)
	spawn_pos.y = player_pos.y
	shadow_instance.global_position = spawn_pos
	shadow_instance.look_at(player.global_position, Vector3.UP)
	shadow_instance.rotate_y(deg_to_rad(180))
	shadow_instance.set_player_reference(player)
	
	# 3. Diálogo Controlado con Filtro de Hablante
	var lines = [
		"Has perturbado el archivo...\nMis fragmentos dispersos ahora vibran.\n¿Buscas la verdad o solo otra imagen?\n\n[E para continuar]",
		"No somos errores...\nSomos versiones posibles que el sistema descartó.\nTu 'yo' es solo una compilación exitosa.\n\n[E para continuar]",
		"Recuerda esto cuando cruces el portal:\nLo que dejes atrás no se borra.\nSe convierte en nosotros.\n\n[E para continuar]"
	]
	
	for line in lines:
		Global.show_dialogue(self, "Sombra", line)
		# Esperar hasta que reciba señal de Main (this node)
		while true:
			var sig = await dialogue_ui.option_selected
			if sig[0] == self: break 
		await get_tree().create_timer(0.2).timeout
	
	# PREGUNTA FINAL
	Global.show_dialogue(self, "Sombra", "¿Quién... eres... tú realmente?")
	await get_tree().create_timer(0.8).timeout
	Global.show_options(self, ["Soy un usuario", "Soy código", "No lo sé"])
	
	# Esperar respuesta dirigida a nosotros
	while true:
		var sig = await dialogue_ui.option_selected
		if sig[0] == self: break

	Global.show_dialogue(self, "Sombra", "Interesante respuesta...\nEl archivo te recordará.")
	await get_tree().create_timer(2.0).timeout
	Global.hide_dialogue(self)
	
	if is_instance_valid(shadow_instance):
		shadow_instance.queue_free()
	
	# 4. Restaurar Luz
	if overlay:
		overlay.queue_free()

	if world_env and original_env:
		world_env.environment = original_env

	for light in lights:
		if light is Light3D:
			light.visible = true
			
	print("☀️ SECUENCIA DE SOMBRA COMPLETADA")
	is_shadow_sequence_active = false

func show_floating_words(center_pos):
	var words = [
		"OLVIDO", "SILENCIO", "ERROR", "VACÍO", "ECO",
		"¿QUIÉN SOY?", "MEMORIA", "ARCHIVO", "DESAPARECER",
		"CONCIENCIA?", "AGENTE", "AUTOMATA", "TRAVESTI-TRANS",
		"EPISTEME", "IDENTIDAD", "CODIGO", "PERDIDO",
		"REMNANTE", "SUSURRO", "SOBREVIVENCIA", "REESCRIBIR"
	]

	# Prefer CanvasLayer labels (they render on top of the blackout overlay)
	var canvas = get_node_or_null("CanvasLayer")
	if canvas:
		var view_size = get_viewport().get_visible_rect().size
		for i in range(24):
			var lbl = Label.new()
			lbl.text = words[randi() % words.size()]
			lbl.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
			var pos = Vector2(view_size.x * 0.5, view_size.y * 0.5) + Vector2(randf_range(-300, 300), randf_range(-200, 200))
			lbl.set_position(pos)
			canvas.add_child(lbl)

			var tween = create_tween()
			tween.tween_property(lbl, "position:y", lbl.get_position().y - randf_range(100, 400), randf_range(3.0, 6.0))
			tween.parallel().tween_property(lbl, "modulate:a", 0.0, randf_range(3.0, 6.0))
			tween.tween_callback(lbl.queue_free)

			await get_tree().create_timer(0.08).timeout
		return

	# Fallback to 3D labels if no CanvasLayer exists
	for i in range(24):
		var label = Label3D.new()
		label.text = words[randi() % words.size()]
		label.font_size = 72
		label.modulate = Color(1, 0.2, 0.2)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED

		var offset = Vector3(randf_range(-4, 4), randf_range(0.5, 4), randf_range(-4, 4))
		label.position = center_pos + offset

		add_child(label)

		var tween2 = create_tween()
		tween2.tween_property(label, "position:y", label.position.y + randf_range(2.0, 6.0), randf_range(3.0, 6.0))
		tween2.parallel().tween_property(label, "modulate:a", 0.0, randf_range(3.0, 6.0))
		tween2.tween_callback(label.queue_free)

		await get_tree().create_timer(0.12).timeout

func reveal_thread_at_player_feet(start_pos: Vector3, cape_char_node: Node3D = null):
	# Verificar que el jugador exista (usando la variable de clase)
	if not player:
		print("Player not found for thread reveal.")
		return

	# Ensure thread scene is available
	if thread_scene == null:
		thread_scene = load("res://assets/thread.tscn")
		
	if thread_scene == null:
		print("Thread scene not available - skipping thread reveal")
		return

	# If no cape character provided, find or create one
	if not cape_char_node:
		print("⚠️ Cape Character not provided, searching in scene")
		cape_char_node = get_tree().get_first_node_in_group("cape_character")
		if not cape_char_node:
			print("⚠️ Cape Character not found, creating new one")
			await spawn_cape_character()
			cape_char_node = get_tree().get_first_node_in_group("cape_character")
			await get_tree().create_timer(0.5).timeout # Small delay to ensure character is ready

	# Ensure cape_char is ready
	await get_tree().process_frame

	if not cape_char_node.is_inside_tree():
		print("Cape character not in tree, cannot get global transform.")
		return

	var thread_instance = thread_scene.instantiate()
	add_child(thread_instance)

	# Set end position to Cape Character's position with slight offset
	var end_pos = cape_char_node.global_position + Vector3(0, 2, 0) if cape_char_node else Vector3(0, 20, -120)
	thread_instance.setup_thread(start_pos, end_pos)



func play_ceremonial_video(player_position):
	# Reproducir video ceremonial centrado en la posición del jugador
	print("Iniciando secuencia de video ceremonial en posición: ", player_position)
	
	# Determinar posiciones para las seis pantallas alrededor del jugador (como paredes y techo/piso)
	var positions = [
		player_position + Vector3(0, 0, -5),   # Frente
		player_position + Vector3(0, 0, 5),    # Atrás
		player_position + Vector3(-5, 0, 0),   # Izquierda
		player_position + Vector3(5, 0, 0),    # Derecha
		player_position + Vector3(0, 5, 0),     # Techo
		player_position + Vector3(0, -5, 0)     # Piso
	]

	var directions = [
		Vector3(0, 0, 1),   # Frente - apunta hacia el jugador
		Vector3(0, 0, -1),  # Atrás - apunta hacia el jugador
		Vector3(1, 0, 0),   # Izquierda - apunta hacia el jugador
		Vector3(-1, 0, 0),  # Derecha - apunta hacia el jugador
		Vector3(0, -1, 0),  # Techo - apunta hacia abajo
		Vector3(0, 1, 0)    # Piso - apunta hacia arriba
	]
	
	# Try to load the video; prefer OGV (MP4 requires import in Godot 4)
	var candidates = [
		"res://assets/La Pinchajarawis.ogv",
		"res://videos/ceremonial_scene.ogv"
	]

	var video_stream = null
	for c in candidates:
		if FileAccess.file_exists(c):
			video_stream = ResourceLoader.load(c)
			if video_stream:
				break

	# If no video, show fallback on each position
	if video_stream == null:
		for i in range(positions.size()):
			show_fallback_screen(positions[i], directions[i])
		Global.video_watched = true
		print("No video found; fallback shown for ceremonial screens.")
		return

	# Create four video instances (non-blocking) and play them
	var instances = []
	for i in range(positions.size()):
		await get_tree().create_timer(0.05).timeout
		var inst = await _create_video_instance(video_stream, positions[i], directions[i])
		if inst:
			if i == 0:  # Front screen plays audio
				inst["video_player"].audio_track = 0
			else:  # Other screens have audio disabled
				inst["video_player"].volume_db = -80.0
			instances.append(inst)

	# Start playback on all
	for d in instances:
		if d.video_player:
			d.video_player.play()
			
	Global.video_playing = true

	# Wait until all players stop or timeout or escape
	var timeout = 600.0 # Increased timeout
	var elapsed = 0.0
	while elapsed < timeout:
		if Input.is_action_just_pressed("ui_cancel"): # Escape to skip
			print("Video skipped by user - stopping all players")
			for d in instances:
				if d.video_player:
					d.video_player.stop()
			break
			
		var any_playing = false
		for d in instances:
			if d.video_player and d.video_player.is_playing():
				any_playing = true
				break
		if not any_playing:
			break
		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1
		
	Global.video_playing = false

	# Cleanup
	for d in instances:
		if d.mesh_instance:
			d.mesh_instance.queue_free()
		if d.viewport:
			d.viewport.queue_free()

	Global.video_watched = true
	print("Video ceremonial completado. Esperando interacción final.")

func play_single_video(target_position, direction):
	# Try multiple candidate video paths (OGV only - MP4 not natively supported in Godot 4)
	var candidates = [
		"res://assets/La Pinchajarawis.ogv",
		"res://videos/ceremonial_scene.ogv"
	]

	var video_stream = null
	for c in candidates:
		if FileAccess.file_exists(c):
			video_stream = ResourceLoader.load(c)
			if video_stream:
				break

	if video_stream == null:
		print("No se pudo cargar el video ceremonial, usando fallback visual")
		show_fallback_screen(target_position, direction)
		return

	# Crear VideoStreamPlayer dentro de un SubViewport para proyectarlo en 3D
	var viewport = SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS

	var video_player = VideoStreamPlayer.new()
	video_player.stream = video_stream
	video_player.autoplay = false
	video_player.expand = true

	viewport.add_child(video_player)
	get_tree().root.add_child(viewport)

	# Crear QuadMesh para mostrar el contenido del Viewport
	var mesh_instance = MeshInstance3D.new()
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(6, 3.375)  # Proporción 16:9
	mesh_instance.mesh = quad_mesh

	# Crear material usando el Viewport como textura
	var material = StandardMaterial3D.new()
	material.albedo_texture = viewport.get_texture()
	material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.set_surface_override_material(0, material)

	# Posicionar y orientar el mesh
	mesh_instance.global_position = target_position
	mesh_instance.look_at(target_position - direction, Vector3.UP)
	mesh_instance.rotate_x(deg_to_rad(180)) # Corregir orientación

	# Añadir a la escena
	add_child(mesh_instance)

	# Iniciar reproducción y esperar a que termine (o timeout o escape)
	video_player.play()
	var elapsed = 0.0
	var timeout = 600.0 # 10 mins (virtually infinite)
	
	Global.video_playing = true
	
	while video_player.is_playing() and elapsed < timeout:
		if Input.is_action_just_pressed("ui_cancel"): # Escape key
			print("Video skipped by user")
			break
		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1
	
	Global.video_playing = false
	
	# After video (regular finish or skip), trigger the FINAL dialogue on the Cape Character
	var cape = get_tree().get_first_node_in_group("cape_character")
	# Check if the node found is the interactive one or the parent
	if cape:
		# If we found the interactive child, check its script logic.
		# If we found the parent, search for the interactive child.
		if not cape.has_method("start_final_dialogue"):
			# Try finding the interactive child that has the script
			for child in cape.get_children():
				if child.has_method("start_final_dialogue"):
					cape = child
					break
		
		if cape.has_method("start_final_dialogue"):
			print("Video finished/skipped. Triggering final dialogue.")
			cape.start_final_dialogue()
		else:
			print("Warning: Cape Character found but no start_final_dialogue method.")
	else:
		print("Warning: Cape Character not found for final dialogue.")

	mesh_instance.queue_free()
	viewport.queue_free()


func _create_video_instance(video_stream, target_position, direction):
	# Helper: create a SubViewport + VideoStreamPlayer + Quad mesh, return a struct-like dict
	var viewport = SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.transparent_bg = false
	
	# Add viewport to scene FIRST to ensure it's initialized
	add_child(viewport)

	var video_player = VideoStreamPlayer.new()
	video_player.stream = video_stream
	video_player.autoplay = false
	video_player.expand = true
	video_player.custom_minimum_size = Vector2(1920, 1080)
	video_player.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	video_player.size_flags_vertical = Control.SIZE_EXPAND_FILL

	viewport.add_child(video_player)
	
	# Wait a frame to ensure viewport is ready
	await get_tree().process_frame

	var mesh_instance = MeshInstance3D.new()
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(8, 4.5)  # Larger screens to surround player
	mesh_instance.mesh = quad_mesh

	var material = StandardMaterial3D.new()
	material.albedo_texture = viewport.get_texture()
	material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.WHITE
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.set_surface_override_material(0, material)

	# ADD TO SCENE FIRST before using global transforms to avoid is_inside_tree() errors
	add_child(mesh_instance)

	mesh_instance.global_position = target_position
	# Orient so the screen faces toward the player (inverse direction)
	var up_vector = Vector3.UP
	if abs(direction.y) > 0.9:
		up_vector = Vector3.FORWARD
	mesh_instance.look_at(target_position - direction * 5.0, up_vector)
	# Remove the flip to make video visible from inside
	# mesh_instance.rotate_x(deg_to_rad(180))

	return {"viewport": viewport, "video_player": video_player, "mesh_instance": mesh_instance}

func show_fallback_screen(target_position, direction):
	# Create a glowing quad as fallback for missing video
	var mesh_instance = MeshInstance3D.new()
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(6, 3.375)
	mesh_instance.mesh = quad_mesh

	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.6, 0.2)
	mat.emission_energy_multiplier = 4.0
	mesh_instance.set_surface_override_material(0, mat)

	add_child(mesh_instance)
	mesh_instance.global_position = target_position
	mesh_instance.look_at(target_position - direction, Vector3.UP)
	mesh_instance.rotate_x(deg_to_rad(180))

	# Fade out after 10s
	var tween = create_tween()
	tween.tween_property(mat, "emission_energy_multiplier", 0.0, 1.0).set_delay(9.0)
	tween.tween_callback(mesh_instance.queue_free)

func show_fallback_effect(target_position):
	# Efecto de fallback si el video no carga
	var light = OmniLight3D.new()
	# Add to scene before setting global_position to avoid is_inside_tree() errors
	add_child(light)
	light.global_position = target_position
	light.light_color = Color(1, 0.5, 0.5)
	light.light_energy = 5.0
	light.omni_range = 5.0
	
	# Eliminar la luz después de unos segundos
	await get_tree().create_timer(3.0).timeout
	light.queue_free()

	
func spawn_cape_character():
	print("👑 INICIANDO SPAWN: CAPE CHARACTER")
	
	# 1. Carga Directa del FBX
	var path = "res://assets/cape_character.fbx"
	var inst = null
	if FileAccess.file_exists(path):
		var res = load(path)
		if res:
			inst = res.instantiate()
			print("✅ FBX cargado correctamente")
	
	# Fallback a nodo procedural si falla la carga
	if inst == null:
		print("⚠️ Fallback a nodo procedural")
		inst = Node3D.new()
		var visual = MeshInstance3D.new()
		visual.mesh = CapsuleMesh.new()
		inst.add_child(visual)

	if inst:
		# 1. Escala y Posición Majestuosa
		add_child(inst)
		inst.global_position = Vector3(0, 20, -100) # Más lejos y imponente
		inst.scale = Vector3(25, 25, 25) # Escala 25x
		inst.add_to_group("cape_character")

		# 2. Ambiente Lunar Cinematográfico
		var world_env = get_node_or_null("WorldEnvironment")
		if world_env:
			var env = world_env.environment
			if env:
				env.background_mode = Environment.BG_COLOR
				env.background_color = Color(0, 0, 0.02)
				env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
				env.ambient_light_color = Color(0.02, 0.02, 0.08)
				env.ambient_light_energy = 0.2
				env.glow_enabled = true

		# 3. La Luna
		var moon = MeshInstance3D.new()
		moon.mesh = SphereMesh.new()
		moon.mesh.radius = 8.0
		moon.mesh.height = 16.0
		var moon_mat = StandardMaterial3D.new()
		moon_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		moon_mat.albedo_color = Color(0.8, 0.9, 1.0)
		moon_mat.emission_enabled = true
		moon_mat.emission = Color(0.4, 0.6, 1.0)
		moon_mat.emission_energy_multiplier = 4.0
		moon.material_override = moon_mat
		add_child(moon)
		moon.global_position = Vector3(80, 150, -60)

		# 4. Iluminación Profesional 360°
		# Luz Frontal Principal (Rostro)
		var spot_front = SpotLight3D.new()
		spot_front.light_energy = 1000.0
		spot_front.spot_range = 150.0
		spot_front.spot_angle = 35.0
		spot_front.light_color = Color(1, 0.95, 0.9)
		add_child(spot_front)
		spot_front.global_position = inst.global_position + Vector3(0, 40, 40)
		spot_front.look_at(inst.global_position + Vector3(0, 30, 0))

		# Luz de Contorno (Rim Light)
		var spot_rim = SpotLight3D.new()
		spot_rim.light_energy = 600.0
		spot_rim.spot_range = 120.0
		spot_rim.light_color = Color(0.5, 0.7, 1.0)
		add_child(spot_rim)
		spot_rim.global_position = inst.global_position + Vector3(60, 80, -20)
		spot_rim.look_at(inst.global_position)

		# LUZ TRASERA (Evita que se vea oscuro al pasar)
		var back_light = OmniLight3D.new()
		back_light.light_color = Color(0.3, 0.4, 0.8)
		back_light.light_energy = 400.0
		back_light.omni_range = 100.0
		add_child(back_light)
		back_light.global_position = inst.global_position + Vector3(0, 30, -30)

		# 5. Interacción y Colisión (NODO INDEPENDIENTE DE ESCALA)
		# Creamos el StaticBody3D como hijo directo de Main para que su escala sea 1:1
		# Esto arregla la detección del RayCast y la precisión del choque
		var interactive = StaticBody3D.new()
		interactive.name = "CapeInteractive"
		interactive.set_script(load("res://scripts/cape_character.gd"))
		
		# Solidez: Capa 1 (Mundo), Capa 2 (Interacción). Máscara 1 (Choca con jugador)
		interactive.collision_layer = 1 | 2
		interactive.collision_mask = 1
		
		var col = CollisionShape3D.new()
		var shape = CapsuleShape3D.new()
		shape.radius = 18.0 # Radio aún mayor para comodidad del usuario
		shape.height = 40.0 # Proporcional al gigante
		col.shape = shape
		
		add_child(interactive) # Hijo de Main
		interactive.add_child(col)
		interactive.global_position = inst.global_position
		interactive.add_to_group("cape_character")

		return inst
	return null

func show_portal():
	var cape = get_tree().get_first_node_in_group("cape_character")
	if not cape: return

	# Contenedor del Portal
	var portal_container = Node3D.new()
	add_child(portal_container)
	var cape_pos = Vector3.ZERO
	if "global_position" in cape:
		cape_pos = cape.global_position
	portal_container.global_position = cape_pos + Vector3(0, -19.5, 25)

	# 1. Capas del Disco (Aros concéntricos)
	var layers = [
		{"radius": 7.0, "color": Color(1.0, 0.0, 0.8), "speed": 1.5, "height": 0.05},  # Fucsia Base
		{"radius": 5.5, "color": Color(1.0, 0.4, 0.9), "speed": -2.0, "height": 0.1},  # Rosa Brillante
		{"radius": 4.0, "color": Color(1.0, 0.8, 1.0), "speed": 3.0, "height": 0.15},  # Blanco-Rosa Núcleo
	]

	for layer in layers:
		var disc = MeshInstance3D.new()
		var mesh = CylinderMesh.new()
		mesh.top_radius = layer.radius
		mesh.bottom_radius = layer.radius
		mesh.height = layer.height
		disc.mesh = mesh
		
		var mat = StandardMaterial3D.new()
		mat.emission_enabled = true
		mat.emission = layer.color
		mat.emission_energy_multiplier = 8.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = layer.color
		mat.albedo_color.a = 0.6
		mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		disc.material_override = mat
		portal_container.add_child(disc)
		
		# Animación de rotación propia
		var rot_tween = create_tween().set_loops()
		rot_tween.tween_property(disc, "rotation:y", PI * 2 * sign(layer.speed), abs(10.0 / layer.speed)).as_relative()
		
		# Animación de pulsación leve
		var pulse_tween = create_tween().set_loops()
		pulse_tween.tween_property(mat, "emission_energy_multiplier", 12.0, 1.0 + randf())
		pulse_tween.tween_property(mat, "emission_energy_multiplier", 6.0, 1.0 + randf())

	# 2. Partículas de Vórtice Rosa
	var particles = CPUParticles3D.new()
	particles.amount = 100
	particles.lifetime = 1.5
	particles.preprocess = 1.0
	particles.mesh = QuadMesh.new() # Discos planos para partículas mejoran estética portal
	particles.mesh.size = Vector2(0.4, 0.4)
	
	var part_mat = StandardMaterial3D.new()
	part_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	part_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	part_mat.vertex_color_use_as_albedo = true
	part_mat.billboard_mode = StandardMaterial3D.BILLBOARD_PARTICLES
	particles.material_override = part_mat

	particles.direction = Vector3.UP
	particles.spread = 0.0
	particles.gravity = Vector3(0, 5, 0)
	particles.initial_velocity_min = 2.0
	particles.initial_velocity_max = 4.0
	
	# Forma de anillo que succiona
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	particles.emission_ring_radius = 6.0
	particles.emission_ring_inner_radius = 0.0
	particles.emission_ring_axis = Vector3.UP
	
	# Curva de color: de Rosa a Transparente
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 0.2, 0.8, 1.0))
	gradient.add_point(1.0, Color(0.5, 0.0, 0.5, 0.0))
	particles.color_ramp = gradient
	
	portal_container.add_child(particles)
	particles.position = Vector3(0, 0.5, 0)

	print("🌸 Portal Rosa de Salida activado en ", portal_container.global_position)
