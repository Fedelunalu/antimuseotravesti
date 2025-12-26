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
var star_triggered = false # Para disparar la estrella fugaz solo una vez

# --- Variables de Mejora Estética ---
@export var glitch_scene: PackedScene
var glitch_overlay: Node = null
var world_flicker_timer = 0.0
var guidance_thread_timer = 0.0

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
	
	# Estética: Polvo de Datos
	setup_environment_particles()

func _process(_delta):
	# Las partículas ambientales siguen al jugador para estar siempre alrededor de él
	var env_particles = get_node_or_null("EnvironmentParticles")
	if env_particles and player:
		env_particles.global_position = player.global_position
	
	# Hilos del Deseo (Guía poética)
	update_guidance_threads(_delta)
	
	# --- ESTRELLA FUGAZ TRIGGER ---
	if player and not star_triggered:
		if player.current_state == 1: # PlayerState.FLYING = 1
			# Pequeño delay tras despegar para que no sea instantáneo
			await get_tree().create_timer(3.0).timeout
			if player and player.current_state == 1:
				star_triggered = true
				spawn_shooting_star()

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
	
	# 1. Apagón (Oscuridad Total Real con Overlay)
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
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(overlay)
		
	# Apagar luces ambientales (opcional, el overlay ya tapa todo)
	if world_env:
		original_env = world_env.environment
		var dark_env = original_env.duplicate()
		dark_env.ambient_light_color = Color.BLACK
		world_env.environment = dark_env
	
	await get_tree().create_timer(1.0).timeout
	
	# 2. Palabras Flotantes (Ahora en 2D sobre el overlay)
	show_floating_words_2d(canvas)
	await get_tree().create_timer(6.0).timeout
	
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
	
	# 3. Diálogo Controlado (Sutil y Poético)
	var lines = [
		"El hilo se tensa... ¿sientes el tirón de lo que aún no ha sido contado?\nNo busques el centro, aquí solo hay orillas que se deshacen.\n\n[E para continuar]",
		"Somos la huella de un tacto que el aire olvidó, un nudo en la garganta del tiempo.\n¿Buscas una salida, o solo un eco que te devuelva tu propio nombre?\n\n[E para continuar]",
		"Mira el reverso de la seda... allí donde el color se vuelve herida y el nudo, silencio.\nNo hay mapas, solo el vaivén de lo que fuimos y lo que no quisieron que fuéramos.\n\n[E para continuar]"
	]
	
	for line in lines:
		Global.show_dialogue(self, "Sombra", line)
		while true:
			var sig = await dialogue_ui.option_selected
			if sig[0] == self: break 
		await get_tree().create_timer(0.2).timeout
	
	# PREGUNTA FINAL
	Global.show_dialogue(self, "Sombra", "¿Eres la costura o la ruptura?")
	await get_tree().create_timer(0.8).timeout
	Global.show_options(self, [
		"Soy el nudo que resiste", 
		"Soy el agua que se escapa", 
		"Soy el silencio entre dos hilos"
	])
	
	# Esperar respuesta dirigida a nosotros
	while true:
		var sig = await dialogue_ui.option_selected
		if sig[0] == self: break

	Global.show_dialogue(self, "Sombra", "El archivo guarda tu susurro...\nVe, antes de que el sol se vuelva ceniza.")
	await get_tree().create_timer(3.0).timeout
	Global.hide_dialogue(self)
	
	if is_instance_valid(shadow_instance):
		shadow_instance.queue_free()
	
	# 4. Restaurar Luz y Entorno
	if overlay:
		overlay.queue_free()
		
	if world_env and original_env:
		world_env.environment = original_env
	
	var lights = get_tree().get_nodes_in_group("lights")
	for light in lights:
		if light is Light3D:
			light.visible = true
			
	print("☀️ SECUENCIA DE SOMBRA COMPLETADA")
	is_shadow_sequence_active = false

func show_floating_words_2d(canvas):
	if not canvas: return
	
	var words = [
		"HUECO", "DERRUMBE", "REVERSO", "OLVIDO", "NADA",
		"LABERINTO", "COSTURA", "NUDO", "TRAVESTI",
		"HILO", "ESPEJO", "MANCHA", "REFLEJO", "SOMBRA",
		"VACÍO", "SEDA", "HUMO", "MÁSCARA", "ABISMO"
	]
	
	var view_size = get_viewport().get_visible_rect().size
	
	# 20 Palabras con transiciones muy lentas y etéreas
	for i in range(20):
		var lbl = Label.new()
		lbl.text = words[randi() % words.size()]
		# Tamaño variado pero sutil
		lbl.add_theme_font_size_override("font_size", randi_range(20, 40))
		lbl.modulate = Color(1.0, 0.5, 0.7, 0.0) # Rosa pálido etéreo
		canvas.add_child(lbl)
		
		# Posición aleatoria suave
		lbl.position = Vector2(randf_range(view_size.x * 0.1, view_size.x * 0.9), randf_range(view_size.y * 0.2, view_size.y * 0.8))
		
		var tween = create_tween().set_parallel(true)
		var duration = randf_range(4.0, 7.0) # Transiciones lentas
		
		# Movimiento de deriva lenta
		var drift = Vector2(randf_range(-50, 50), randf_range(-50, 50))
		tween.tween_property(lbl, "position", lbl.position + drift, duration).set_trans(Tween.TRANS_SINE)
		
		# Fade in y out muy suave
		tween.tween_property(lbl, "modulate:a", 0.5, duration * 0.3)
		tween.chain().tween_property(lbl, "modulate:a", 0.0, duration * 0.5).set_delay(duration * 0.2)
		
		# Escala lenta
		tween.parallel().tween_property(lbl, "scale", Vector2(1.1, 1.1), duration)
		
		tween.tween_callback(lbl.queue_free).set_delay(duration)
		
		# Delay entre palabras para no saturar
		await get_tree().create_timer(randf_range(0.3, 0.6)).timeout

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
		print("⚠️ Cape Character not provided, searching or spawning...")
		cape_char_node = get_tree().get_first_node_in_group("cape_character")
		if not cape_char_node:
			cape_char_node = await spawn_cape_character()
			
	if not cape_char_node:
		print("❌ Error: Could not spawn Cape Character for thread reveal")
		return

	# Ensure cape_char is ready in tree
	if not cape_char_node.is_inside_tree():
		await get_tree().process_frame
		
	await get_tree().create_timer(0.5).timeout # Small delay to ensure character is ready

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

func play_dragona_memory_video():
	print("🎞️ Iniciando RECUERDOS DE LA DRAGONA")
	var video_path = "res://dragonanacefinal.ogv"
	
	if not ResourceLoader.exists(video_path):
		video_path = "res://dragona-naciendo.ogv"
		
	if not ResourceLoader.exists(video_path):
		print("❌ ERROR: No se encontró el video de la dragona en ", video_path)
		# No hacemos fallback a La Pinchajarawis para no confundir audios
		
	# Re-use the multi-screen logic or single full-screen? 
	# User mentioned "play a video for Dragona memories", usually full screen is better for impact.
	# But we'll follow the established ceremonial style for consistency if preferred.
	# Let's use a single front screen for the "memory" to make it more intimate.
	
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node:
		var target_pos = player_node.global_position + (player_node.global_transform.basis.z * -5.0)
		var direction = player_node.global_transform.basis.z
		await play_single_video(target_pos, direction, video_path)

func play_single_video(target_position, direction, custom_path = ""):
	var video_stream = null
	if custom_path != "" and ResourceLoader.exists(custom_path):
		video_stream = ResourceLoader.load(custom_path)
	
	if video_stream == null:
		print("No se pudo cargar el video solicitado: ", custom_path)
		# No fallback to other specific story videos
		return

	# Crear VideoStreamPlayer dentro de un SubViewport para proyectarlo en 3D
	var viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.own_world_3d = true # Isolar para evitar interferencias
	
	var video_player = VideoStreamPlayer.new()
	video_player.stream = video_stream
	video_player.autoplay = false
	video_player.expand = true
	video_player.volume_db = -5.0 # Volumen estándar para diálogos de dragona
	video_player.anchor_right = 1.0
	video_player.anchor_bottom = 1.0
	video_player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	viewport.add_child(video_player)
	add_child(viewport)

	# 1. Crear el material
	var material = StandardMaterial3D.new()
	material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	
	# 2. Configurar el Mesh
	var mesh_instance = MeshInstance3D.new()
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(16, 9) # Doble de grande (antes 8x4.5)
	mesh_instance.mesh = quad_mesh
	mesh_instance.set_surface_override_material(0, material)
	
	# 3. Añadir a la escena
	add_child(mesh_instance)
	
	# 4. Posicionar y orientar
	mesh_instance.global_position = target_position
	# Forzar que el video mire al jugador (usando -direction para invertir la cara del quad)
	mesh_instance.look_at(target_position - direction, Vector3.UP)
	
	# 5. Esperar un frame y asignar textura
	await get_tree().process_frame
	material.albedo_texture = viewport.get_texture()
	
	# Iniciar reproducción
	video_player.play()
	
	# Sonido Atmosférico: Cajita Musical Tierna con Glitches
	var audio_player = AudioStreamPlayer.new()
	var audio_gen = AudioStreamGenerator.new()
	audio_gen.mix_rate = 44100
	audio_gen.buffer_length = 0.5
	audio_player.stream = audio_gen
	audio_player.volume_db = -12.0
	add_child(audio_player)
	audio_player.play()
	
	var playback = audio_player.get_stream_playback()
	
	var elapsed = 0.0
	var timeout = 600.0
	var note_timer = 0.0
	var current_note_freq = 0.0
	var note_envelope = 0.0
	
	# Escala pentatónica para que sea "tierna" y armoniosa
	var music_scale = [523.25, 587.33, 659.25, 783.99, 880.00, 1046.50] # C5, D5, E5, G5, A5, C6
	
	Global.video_playing = true
	
	while video_player.is_playing() and elapsed < timeout:
		if Input.is_action_just_pressed("ui_cancel"):
			break
		
		# Generación de notas (Cajita musical)
		if note_timer <= 0:
			current_note_freq = music_scale[randi() % music_scale.size()]
			note_envelope = 1.0 # Reiniciar envolvente
			note_timer = randf_range(0.4, 0.8) # Ritmo pausado
			
			# GLITCH: A veces la nota salta de tono bruscamente
			if randf() < 0.15:
				current_note_freq *= randf_range(0.5, 2.0)
		
		if playback.get_frames_available() > 0:
			var sample_rate = 44100.0
			for j in range(playback.get_frames_available()):
				var t = elapsed + (j / sample_rate)
				
				# Sintetizar nota (Sine pura para sonido de cajita)
				var val = sin(t * 2.0 * PI * current_note_freq) * note_envelope * 0.3
				
				# GLITCH: Ráfagas de ruido blanco
				if randf() < 0.0005:
					val += randf_range(-0.5, 0.5)
					
				playback.push_frame(Vector2(val, val))
				
				# Decaimiento de la nota (exponencial suave)
				note_envelope = max(0.0, note_envelope - 0.00005)
		
		var delta_wait = 0.05
		await get_tree().create_timer(delta_wait).timeout
		elapsed += delta_wait
		note_timer -= delta_wait
	
	if audio_player:
		audio_player.stop()
		audio_player.queue_free()
	
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
	
	Global.video_playing = false
	
	# Cleanup
	if is_instance_valid(mesh_instance):
		mesh_instance.queue_free()
	if is_instance_valid(viewport):
		viewport.queue_free()
	
	print("Video single finalizado.")

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
	video_player.volume_db = -20.0 # VOLUMEN BAJO para personaje gigante
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
	if ResourceLoader.exists(path):
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

	# 3. Area3D de Entrada al Portal para Cierre de Nivel
	var area = Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 1 # Choca con el jugador
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 4.0
	col.shape = shape
	area.add_child(col)
	portal_container.add_child(area)
	
	area.body_entered.connect(_on_portal_entered)

	print("🌸 Portal Rosa de Salida activado en ", portal_container.global_position)

func spawn_shooting_star():
	print("🌠 ESTRELLA FUGAZ EMOTIVA")
	
	var cam = get_viewport().get_camera_3d()
	if not cam: return
	
	# --- ESTRELLA ÚNICA, GRANDE Y EMOTIVA ---
	var star = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 2.5
	sphere.height = 5.0
	star.mesh = sphere
	
	# Material muy brillante y suave
	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(2.5, 2.3, 3.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.98, 1.0)
	mat.emission_energy_multiplier = 25.0
	star.material_override = mat
	
	add_child(star)
	
	# Trayectoria: Entra desde arriba a la izquierda, cruza lentamente, cae al horizonte
	var start_pos = cam.global_position + Vector3(-120, 100, -80)
	var mid_pos = cam.global_position + Vector3(0, 60, -80)
	var end_pos = cam.global_position + Vector3(120, -30, -80)  # Cae al horizonte
	
	star.global_position = start_pos
	
	# Trail largo, denso y continuo
	var trail = CPUParticles3D.new()
	trail.amount = 200
	trail.lifetime = 3.0  # Trail muy largo
	trail.emitting = true
	trail.mesh = QuadMesh.new()
	trail.mesh.size = Vector2(1.2, 1.2)
	
	var p_mat = StandardMaterial3D.new()
	p_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	p_mat.vertex_color_use_as_albedo = true
	p_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	p_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD  # Brillo aditivo
	trail.material_override = p_mat
	
	trail.gravity = Vector3.ZERO
	trail.initial_velocity_min = 0.1
	trail.initial_velocity_max = 0.3
	
	# Gradiente suave y continuo
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 1.0, 1.0, 1.0))
	gradient.add_point(0.3, Color(0.95, 0.95, 1.0, 0.8))
	gradient.add_point(0.7, Color(0.85, 0.85, 1.0, 0.4))
	gradient.add_point(1.0, Color(0.7, 0.7, 0.9, 0.0))
	trail.color_ramp = gradient
	
	star.add_child(trail)
	
	# Animación MUY LENTA y EMOTIVA (8 segundos)
	var tween = create_tween()
	# Primera mitad: entrada suave
	tween.tween_property(star, "global_position", mid_pos, 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Segunda mitad: caída al horizonte
	tween.tween_property(star, "global_position", end_pos, 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(star.queue_free)
	
	# DIÁLOGO INTERNO - Esperar un poco para que vean la estrella primero
	await get_tree().create_timer(1.5).timeout
	Global.show_dialogue(self, "Tú", "¿Has visto eso? Cruza el archivo como una herida de luz...\n¿A dónde irá lo que deseamos cuando el código se apague?\nPide un deseo. Hazlo ahora, antes de que el silencio lo reclame.\n\n[Presiona TAB para abrir tu Bitácora y escribir tu deseo]\n[Presiona E para continuar]")
	
	# ESPERAR CIERRE - Una sola señal
	var sig = await dialogue_ui.option_selected
	print("🔔 Señal recibida de diálogo: ", sig)
	if sig.size() > 0 and sig[0] == self:
		print("✅ Cerrando diálogo de estrella")
		Global.hide_dialogue(self)
	
	Global.add_signal("ESTRELLA DETECTADA: El sistema permite la inyección de un deseo manual.", "star_wish")

func _on_portal_entered(body):
	if body.is_in_group("player"):
		if Global.current_quest_stage < Global.QuestStage.PORTAL_OPEN: return # Solo si está abierto
		
		print("🌀 JUGADOR ENTRÓ AL PORTAL - FINALIZANDO NIVEL")
		
		# 1. Detener movimiento
		if body.has_method("set_physics_process"):
			body.set_physics_process(false)
		
		# 2. Mensaje de Umbral - Esperar TAB específicamente
		Global.show_dialogue(self, "Sistema", "Cruzando el umbral...\nTu rastro en el archivo ha sido procesado.\n\nAntes de partir, mira lo que has tejido.\n\n[Presiona TAB para abrir tu Bitácora final]")
		
		# Esperar a que el usuario abra la bitácora con TAB (no aceptar E)
		await get_tree().create_timer(1.0).timeout
		if journal_ui:
			# Esperar a que la bitácora se abra (cuando presione TAB)
			while not journal_ui.visible:
				await get_tree().create_timer(0.1).timeout
		
		Global.hide_dialogue(self)
			
		# 3. Mostrar Bitácora Automáticamente en la pestaña de ESCRITURA
		if journal_ui:
			journal_ui.visible = true
			# Cambiar a la pestaña de escritura (índice 0)
			if journal_ui.has_node("Panel/TabContainer"):
				journal_ui.get_node("Panel/TabContainer").current_tab = 0
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			
			# Esperar a que cierre la bitácora con TAB
			while journal_ui.visible:
				await get_tree().create_timer(0.1).timeout
		
		# 4. Diálogo final para disolverse
		Global.show_dialogue(self, "Sistema", "El archivo ha registrado tu paso.\nTu huella permanece en el código.\n\n[Presiona E para disolverse en el vacío]")
		
		await get_tree().create_timer(1.0).timeout
		var _sig = await dialogue_ui.option_selected
		Global.hide_dialogue(self)
		
		# 5. Efecto de desvanecimiento negro
		var canvas = get_node_or_null("CanvasLayer")
		if canvas:
			var fade = ColorRect.new()
			fade.color = Color(0, 0, 0, 0)
			fade.anchor_right = 1.0
			fade.anchor_bottom = 1.0
			fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
			canvas.add_child(fade)
			
			var tween = create_tween()
			tween.tween_property(fade, "color:a", 1.0, 3.0)
			await tween.finished
			
			# 6. Mensaje Final
			var label = Label.new()
			label.text = "LA CONCIENCIA SE DISUELVE...\nEL ARCHIVO PERMANECE.\n\nFIN DEL NIVEL 1"
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.anchor_left = 0.5
			label.anchor_top = 0.5
			label.anchor_right = 0.5
			label.anchor_bottom = 0.5
			label.grow_horizontal = Control.GROW_DIRECTION_BOTH
			label.grow_vertical = Control.GROW_DIRECTION_BOTH
			label.add_theme_font_size_override("font_size", 32)
			canvas.add_child(label)
			
			await get_tree().create_timer(5.0).timeout
			# Aquí se podría volver al menú o cerrar
			# get_tree().quit() 
func setup_environment_particles():
	print("✨ Inicializando Polvo de Datos (Ambiente)")
	var particles = CPUParticles3D.new()
	particles.name = "EnvironmentParticles"
	# Cubrir una zona amplia del museo
	particles.amount = 200
	particles.lifetime = 10.0
	particles.preprocess = 5.0
	particles.speed_scale = 0.5
	
	# Caja de emisión grande para abarcar el museo
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = Vector3(100, 50, 100)
	
	# Mesh: Un pequeño cubo/punto brillante
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.05, 0.05, 0.05)
	particles.mesh = mesh
	
	# Material: Unshaded y Rosa/Blanco
	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = StandardMaterial3D.BILLBOARD_ENABLED
	particles.material_override = mat
	
	# Variación de color (Rosa Travesti a Blanco)
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 0.41, 0.7, 0.8)) # Hot Pink
	gradient.add_point(0.5, Color(1, 1, 1, 0.6))      # Blanco
	gradient.add_point(1.0, Color(1, 0.41, 0.7, 0.0)) # Desvanecimiento
	particles.color_ramp = gradient
	
	# Movimiento suave (viento digital)
	particles.direction = Vector3(1, 1, 1)
	particles.spread = 180.0
	particles.gravity = Vector3(0, 0, 0)
	particles.initial_velocity_min = 0.1
	particles.initial_velocity_max = 0.5
	
	# Variación de tamaño
	var size_curve = Curve.new()
	size_curve.add_point(Vector2(0, 0))
	size_curve.add_point(Vector2(0.2, 1))
	size_curve.add_point(Vector2(0.8, 1))
	size_curve.add_point(Vector2(1, 0))
	particles.scale_amount_curve = size_curve
	
	add_child(particles)
	# Centrar en una zona media
	particles.global_position = Vector3(0, 10, -30)

func setup_glitch_overlay():
	if glitch_scene == null:
		glitch_scene = load("res://glitch_overlay.tscn")
	
	if glitch_scene:
		glitch_overlay = glitch_scene.instantiate()
		$CanvasLayer.add_child(glitch_overlay)
		
		# Buscar el control interno que tiene el script (TextureRect)
		if glitch_overlay.has_node("TextureRect"):
			var rect = glitch_overlay.get_node("TextureRect")
			if rect.has_method("show_glitch"):
				rect.show_glitch()

func update_glitch_intensity(_delta):
	if not glitch_overlay: return
	
	var rect = glitch_overlay.get_node_or_null("TextureRect")
	if not rect: return
	
	# Mapear stage a opacidad
	var target_alpha = 0.0
	match Global.current_quest_stage:
		Global.QuestStage.NONE: target_alpha = 0.02 # Muy sutil siempre
		Global.QuestStage.SHADOW_MET: target_alpha = 0.05
		Global.QuestStage.SEARCHING_ARTIFACT: target_alpha = 0.08
		Global.QuestStage.ARTIFACT_FOUND: target_alpha = 0.12
		Global.QuestStage.RIDDLE_ACTIVE: target_alpha = 0.15
		Global.QuestStage.PORTAL_OPEN: target_alpha = 0.2
	
	# Suavizar transición
	rect.self_modulate.a = lerp(rect.self_modulate.a, target_alpha, 0.05)

func update_world_flicker(_delta):
	world_flicker_timer += _delta
	# Solo parpadear si hay inestabilidad (ya conocimos a la sombra)
	if Global.current_quest_stage < Global.QuestStage.SHADOW_MET: return
	
	if world_flicker_timer > 2.0: # Cada 2 segundos intentar un parpadeo
		if randf() < 0.3: # 30% de probabilidad
			flicker_random_artwork()
		world_flicker_timer = 0.0

func flicker_random_artwork():
	var artworks = get_tree().get_nodes_in_group("artwork")
	if artworks.size() > 0:
		var art = artworks[randi() % artworks.size()]
		var tween = create_tween()
		tween.tween_property(art, "visible", false, 0.05)
		tween.tween_property(art, "visible", true, 0.05).set_delay(0.1)
		tween.tween_property(art, "visible", false, 0.03).set_delay(0.2)
		tween.tween_property(art, "visible", true, 0.03).set_delay(0.25)

func update_guidance_threads(_delta):
	if Global.current_quest_stage != Global.QuestStage.SEARCHING_ARTIFACT: return
	
	guidance_thread_timer += _delta
	if guidance_thread_timer > 4.0: # Cada 4 segundos
		if randf() < 0.4: # 40% de probabilidad
			spawn_poetic_guidance_thread()
		guidance_thread_timer = 0.0

func spawn_poetic_guidance_thread():
	# Encontrar el objetivo (obra con ovillo)
	var target_art = null
	for art in get_tree().get_nodes_in_group("artwork"):
		if "is_quest_target" in art and art.is_quest_target:
			target_art = art
			break
	
	if not target_art or not player: return
	
	# Crear un hilo efímero en el aire entre el jugador y el objetivo
	var start_pos = player.global_position + Vector3(randf_range(-5, 5), randf_range(2, 6), randf_range(-5, 5))
	var direction = (target_art.global_position - start_pos).normalized()
	var end_pos = start_pos + (direction * randf_range(3.0, 7.0))
	
	var line = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.01
	cylinder.bottom_radius = 0.01
	cylinder.height = start_pos.distance_to(end_pos)
	line.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.0, 0.2, 0.0) # Rojo transparente
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line.material_override = mat
	
	add_child(line)
	
	# Posicionar y rotar la línea
	line.global_position = (start_pos + end_pos) / 2.0
	line.look_at(end_pos, Vector3.UP)
	line.rotate_x(deg_to_rad(90))
	
	# Animación: Aparecer, brillar, desaparecer
	var tween = create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.6, 1.0)
	tween.tween_property(mat, "albedo_color:a", 0.0, 2.0).set_delay(1.5)
	tween.tween_callback(line.queue_free)
