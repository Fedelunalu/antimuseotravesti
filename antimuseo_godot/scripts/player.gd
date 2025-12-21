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

func update_state(_delta):
	# Si el jugador puede volar y presiona Espacio mientras está en el aire, activar vuelo INMEDIATAMENTE
	if can_fly and Input.is_action_just_pressed("ui_accept") and not is_on_floor():
		current_state = PlayerState.FLYING
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
