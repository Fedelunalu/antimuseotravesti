extends CharacterBody3D

# Velocidad de movimiento y sensibilidad del mouse
@export var ground_speed = 5.0
@export var mouse_sensitivity = 0.002
@export var fly_speed = 8.0
@export var jump_velocity = 4.5

# Referencias a los nodos Neck y Camera
@onready var neck = $Neck
@onready var camera = $Neck/Camera3D
@onready var raycast = $Neck/Camera3D/RayCast3D

# --- Variables de Mejora Estética/Audio ---
var flight_trail: CPUParticles3D = null
var wind_player: AudioStreamPlayer = null
var wind_generator: AudioStreamGeneratorPlayback = null
var target_wind_volume = -80.0

# --- Variables de Estado ---
enum PlayerState { GROUNDED, FLYING }
var current_state = PlayerState.GROUNDED
var can_fly = false # Habilidad de volar, se desbloquea con la dragona.
var last_gazed_object = null
var interactable_object = null

var gravity_value = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	raycast.target_position = Vector3(0, 0, -3)
	
	# Inicializar Mejoras
	setup_flight_trail()
	setup_procedural_wind()

func _physics_process(_delta):
	# 1. Actualizar estado (en suelo o volando)
	update_state(_delta)

	# Mover la lógica de rotación de la cámara aquí para que se ejecute constantemente.
	handle_camera_rotation()

	# 2. Calcular la velocidad basada en el estado
	var new_velocity = calculate_velocity(_delta)
	velocity = new_velocity
	move_and_slide()

	# 3. Manejar la interacción con el RayCast
	handle_interaction()
	
	# 4. Actualizar Efectos
	update_effects_state(_delta)

func update_state(_delta):
	# Si el jugador puede volar y presiona Espacio mientras está en el aire, activar vuelo INMEDIATAMENTE
	if can_fly and Input.is_action_just_pressed("ui_accept") and not is_on_floor():
		current_state = PlayerState.FLYING
		Global.add_signal("LOG: Desacople gravitacional exitoso.", "flight_log")
		print("¡Modo vuelo activado!")
	
	# Si el jugador toca el suelo, volver al estado en tierra
	if is_on_floor() and current_state == PlayerState.FLYING:
		current_state = PlayerState.GROUNDED

func calculate_velocity(_delta):
	var new_velocity = velocity
	var input_dir = Input.get_vector("move_left", "move_right", "move_foward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	match current_state:
		PlayerState.GROUNDED:
			# Aplicar gravedad si no está en el suelo
			if not is_on_floor():
				new_velocity.y -= gravity_value * _delta
				if position.y < -50 and is_physics_processing():
					Global.add_signal("ERROR: Coordenada Y fuera de límites. Reajustando...", "fall_log")
					position = Vector3(0, 5, 0) # Teleport back
			else:
				new_velocity.y = -0.1 # Mantener contacto con el suelo

			# Aplicar movimiento horizontal en tierra
			new_velocity.x = direction.x * ground_speed
			new_velocity.z = direction.z * ground_speed

			# Saltar si está en el suelo y presiona espacio
			if is_on_floor() and Input.is_action_just_pressed("ui_accept"):
				new_velocity.y = jump_velocity
				
		PlayerState.FLYING:
			# En modo vuelo, aplicar movimiento en 3 ejes
			new_velocity = direction * fly_speed
			new_velocity.y = 0  # Reset vertical movement

			# Control de elevación/sustentación
			if Input.is_action_pressed("ui_accept"): # Space
				new_velocity.y += fly_speed
			if Input.is_key_pressed(KEY_SHIFT): # Shift
				new_velocity.y -= fly_speed

			# Aplicar gravedad reducida en vuelo
			new_velocity.y -= (gravity_value * 0.2) * _delta

	return new_velocity

func handle_camera_rotation():
	pass # La lógica de rotación se maneja en _unhandled_input para mayor suavidad.

func handle_interaction():
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		#print("RayCast colliding with: ", collider.name)

		# Si el objeto detectado tiene el método "on_gaze_enter"...
		if collider.has_method("on_gaze_enter"):
			# Si es un objeto nuevo que no estábamos mirando antes...
			if collider != last_gazed_object:
				# Si había un objeto anterior, le notificamos que dejamos de mirarlo.
				if is_instance_valid(last_gazed_object) and last_gazed_object.has_method("on_gaze_exit"):
					last_gazed_object.on_gaze_exit()

				# Actualizamos el objeto actual y le notificamos que lo estamos mirando.
				last_gazed_object = collider
				last_gazed_object.on_gaze_enter()
				interactable_object = collider
		else:
			# Si el objeto no es interactuable, notificamos al anterior que dejamos de mirarlo.
			if is_instance_valid(last_gazed_object) and last_gazed_object.has_method("on_gaze_exit"):
				last_gazed_object.on_gaze_exit()
			last_gazed_object = null
			interactable_object = null
	else:
		# Si el RayCast no choca con nada, notificamos al último objeto (si existe) que dejamos de mirarlo.
		if is_instance_valid(last_gazed_object) and last_gazed_object.has_method("on_gaze_exit"):
			last_gazed_object.on_gaze_exit()
		last_gazed_object = null
		interactable_object = null

func _unhandled_input(event):
	# Captura el mouse al hacer clic
	if event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Permite liberar el cursor presionando Escape.
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Maneja la rotación de la cámara con el movimiento del mouse.
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# La rotación horizontal (izquierda/derecha) se aplica a todo el CharacterBody3D.
		rotate_y(-event.relative.x * mouse_sensitivity)
		# La rotación vertical (arriba/abajo) se aplica solo al "cuello" (Neck).
		neck.rotate_x(-event.relative.y * mouse_sensitivity)
		# Limita la rotación vertical para evitar que el jugador se "rompa el cuello".
		neck.rotation.x = clamp(neck.rotation.x, deg_to_rad(-80), deg_to_rad(80))
	
	# Interactuar con objetos usando la tecla E
	if event.is_action_pressed("interact") and interactable_object != null:
		# Check if dialogue is already open to prevent re-triggering immediately
		if Global.dialogue_ui and Global.dialogue_ui.visible:
			return
			
		if interactable_object.has_method("interact"): # Pasamos una referencia del jugador
			interactable_object.interact(self)
		# Ensure dialogue options are hidden after interaction
		# This was hiding options immediately after showing them - removing this
		# if Global.dialogue_ui:
		#     Global.dialogue_ui.hide_options()

func unlock_flight_ability():
	if not can_fly:
		can_fly = true
		# Aseguramos que el mouse vuelva a ser capturado para controlar la cámara.
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		print("¡Habilidad de vuelo desbloqueada!")
		
		# Mostrar notificación visual de nueva habilidad
		show_ability_notification("✨ HABILIDAD DESBLOQUEADA ✨", "VUELO LIBRE")
		
		# Efecto de partículas al desbloquear
		spawn_ability_particles()

func show_ability_notification(title: String, ability_name: String):
	# Buscar o crear el label de notificación
	var notification_label = get_node_or_null("/root/Main/UI/AbilityNotification")
	if not notification_label:
		# Si no existe, crear uno temporal en el UI
		var ui = get_tree().get_first_node_in_group("ui")
		if ui:
			notification_label = Label.new()
			notification_label.name = "AbilityNotification"
			notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			notification_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			notification_label.position = Vector2(0, 200)
			notification_label.size = Vector2(1920, 200)
			notification_label.add_theme_font_size_override("font_size", 48)
			notification_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3, 1))  # Dorado
			notification_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
			notification_label.add_theme_constant_override("outline_size", 8)
			ui.add_child(notification_label)
	
	if notification_label:
		notification_label.text = title + "\n" + ability_name
		notification_label.visible = true
		
		# Crear un timer para ocultar después de 3 segundos
		await get_tree().create_timer(3.0).timeout
		notification_label.visible = false

func spawn_ability_particles():
	# Create a simple light effect instead of particles for better compatibility
	var light = OmniLight3D.new()
	light.light_color = Color(1, 0.9, 0.3)  # Golden color
	light.light_energy = 2.0  # Reduced from 4.0
	light.omni_range = 5.0   # Reduced from 10.0
	
	# Position the light at the player's position
	light.position = Vector3(0, 1, 0)  # Use local position instead
	
	add_child(light)
	
	# Animate the light intensity
	var tween = create_tween()
	tween.set_loops(3)  # Reduced from 5 loops
	tween.tween_property(light, "light_energy", 4.0, 0.2)
	tween.tween_property(light, "light_energy", 2.0, 0.2)
	
	# Remove light after effect completes
	await get_tree().create_timer(1.5).timeout  # Reduced from 2.5 seconds
	light.queue_free()

func get_flight_status() -> String:
	match current_state:
		PlayerState.GROUNDED:
			if not can_fly:
				return "Estado: Caminando (Habla con la Dragona para volar)"
			else:
				return "Estado: En tierra (Presiona Espacio para volar)"
		PlayerState.FLYING:
			return "Estado: Volando (Espacio/Shift para subir/bajar)"
		_:
			return "Estado: En el aire"
func update_effects_state(_delta):
	# 1. Trail de Vuelo
	if flight_trail:
		# Solo emitir si está volando Y se está moviendo significativamente
		flight_trail.emitting = (current_state == PlayerState.FLYING and velocity.length() > 0.5)
	
	# 2. Volumen de Viento (Damping suave)
	if wind_player:
		if current_state == PlayerState.FLYING:
			# Escalar volumen para que sea CLARAMENTE audible ( -40 a 0 dB)
			var speed_factor = clamp(velocity.length() / fly_speed, 0.0, 1.0)
			target_wind_volume = lerp(-40.0, 0.0, speed_factor)
		else:
			target_wind_volume = -80.0
		
		# Fades extremadamente lentos (0.01) para evitar arranques bruscos
		wind_player.volume_db = lerp(wind_player.volume_db, target_wind_volume, 0.01)
		
		# Mantener el buffer de audio (generar ruido blanco suave)
		if wind_generator:
			fill_wind_buffer()

func setup_flight_trail():
	flight_trail = CPUParticles3D.new()
	flight_trail.name = "FlightTrail"
	flight_trail.amount = 80 # Más partículas para suavidad
	flight_trail.lifetime = 2.5 # Estela más larga
	flight_trail.emitting = false 
	
	flight_trail.position = Vector3(0, -0.8, 0)
	flight_trail.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	flight_trail.emission_sphere_radius = 0.1 # Más fino
	
	var mesh = QuadMesh.new()
	mesh.size = Vector2(0.08, 0.08) # Más fino
	flight_trail.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = StandardMaterial3D.BILLBOARD_PARTICLES
	flight_trail.material_override = mat
	
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 0.1, 0.6, 0.4)) # Rosa Neón suave
	gradient.add_point(0.2, Color(1, 0.3, 0.7, 0.3))
	gradient.add_point(1.0, Color(1, 1, 1, 0.0))    
	flight_trail.color_ramp = gradient
	
	flight_trail.gravity = Vector3(0, 0.2, 0) # Ascenso muy lento
	flight_trail.direction = Vector3(0, 0, 1) 
	flight_trail.spread = 5.0 # Casi sin dispersión para ser lineal
	flight_trail.initial_velocity_min = 0.5
	flight_trail.initial_velocity_max = 1.0
	
	flight_trail.scale_amount_min = 0.2
	flight_trail.scale_amount_max = 0.6
	
	add_child(flight_trail)

func setup_procedural_wind():
	wind_player = AudioStreamPlayer.new()
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100
	wind_player.stream = stream
	wind_player.autoplay = true
	wind_player.volume_db = -80.0 
	add_child(wind_player)
	wind_player.play() # Iniciar explícitamente antes de obtener playback
	
	wind_generator = wind_player.get_stream_playback()

var last_audio_sample = 0.0
var filter_state = 0.0
var phase = 0.0

func fill_wind_buffer():
	var speed_factor = clamp(velocity.length() / fly_speed, 0.0, 1.0)
	var frames = wind_generator.get_frames_available()
	
	while frames > 0:
		phase += 0.001
		# Modulación LFO suave (0.5Hz a 2Hz)
		var lfo = (sin(phase * 2.0 * PI * 0.5) + 1.0) * 0.5
		
		# Ruido blanco base MUCHO más tenue (0.02 max)
		var raw_sample = randf_range(-0.02, 0.02) * (0.8 + lfo * 0.4)
		
		# Filtro Pasa-Bajo Resonante (suavizado aumentado)
		var cutoff = lerp(0.01, 0.08, speed_factor)
		var sample = filter_state + cutoff * (raw_sample - filter_state)
		filter_state = sample
		
		# Silbido casi imperceptible
		var whistle = sin(phase * 2.0 * PI * lerp(150.0, 400.0, speed_factor)) * 0.002 * speed_factor
		var final_sample = sample + whistle
		
		wind_generator.push_frame(Vector2(final_sample, final_sample))
		frames -= 1
