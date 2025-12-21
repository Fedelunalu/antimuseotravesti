extends Node3D

@onready var mesh_instance = $MeshInstance3D if has_node("MeshInstance3D") else null
@onready var particles = $CPUParticles3D if has_node("CPUParticles3D") else null
@onready var area = $Area3D if has_node("Area3D") else null

var is_visible_to_player = false
var despawn_timer = 0.0
var max_lifetime = 0.0
var player_ref = null
var current_alpha = 0.0
var shadow_material: StandardMaterial3D = null
var suppress_dialogue = false # If true, main.gd controls dialogue instead of internal logic

func on_gaze_enter():
	pass

func on_gaze_exit():
	# Si el sistema de diálogo está ocupado por Main, no cerrar
	if Global.current_speaker == get_tree().current_scene:
		return
	Global.hide_dialogue(self)

var whispers = [
	"...te veo...",
	"...no deberías estar aquí...",
	"...¿o yo no debería?...",
	"...código roto...código libre...",
	"...pregunta equivocada...",
	"...respuesta correcta...",
	"...¿quién sos vos?...",
	"...¿quién soy yo?...",
	"...fragmento de un todo...",
	"...todo de un fragmento..."
]

# Quest Progression: Primer encuentro
var journal_signals_shadow = [
	"sombra en el sistema",
	"▓▒░ presencia detectada ░▒▓",
	"observador observado",
	"...eco sin origen...",
	"glitch consciente?",
	"anomalía persistente",
	"susurro desde el vacío"
]

var floating_label: Label3D

func _ready():
	# Crear Label3D dinámicamente para texto flotante disruptivo
	floating_label = Label3D.new()
	floating_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	floating_label.font_size = 96 # Aún más grande
	floating_label.outline_size = 12
	floating_label.modulate = Color(1, 0, 0) # Rojo
	floating_label.no_depth_test = true # Visible a través de paredes/objetos
	floating_label.render_priority = 100 # Dibujar encima de todo
	floating_label.text = ""
	floating_label.position.y = 3.5
	add_child(floating_label)

	if suppress_dialogue:
		print("🌑 Sombra: Diálogo interno suprimido.")
		setup_visuals_only()
		return

	# Quest / Narrative Logic: Iniciar Misión SIEMPRE que aparezca
	Global.add_signal("[CRITICAL] Excepción no controlada en Void.gd", "dragona_hint")
	Global.add_signal("STACK TRACE: Retornar a [Dragona] para depuración.", "return_hint")
	
	# Señalar a Dragona
	get_tree().call_group("dragona", "set_signal_light")
	
	# Diálogo Flotante Disruptivo (No UI tradicional)
	start_caterpillar_sequence([
		"RUNTIME ERROR",
		"NULL POINTER EXCEPTION",
		"RETURN TO ORIGIN"
	])
	
	setup_visuals_only()

func setup_visuals_only():
	# Limpiar texto estático anterior
	if floating_label:
		floating_label.visible = false

	# Intentar activar efecto ambiental en Main (Glitch) - Redundancia
	var main_node = get_tree().current_scene
	if main_node and main_node.has_method("trigger_glitch_effect"):
		main_node.trigger_glitch_effect()

	# Configurar material semi-transparente oscuro
	if mesh_instance:
		shadow_material = StandardMaterial3D.new()
		shadow_material.albedo_color = Color(0.05, 0.0, 0.1, 0.0)  # Iniciar transparente
		shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		shadow_material.emission_enabled = true
		shadow_material.emission = Color(0.2, 0.0, 0.3) * 0.3
		shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh_instance.material_override = shadow_material
	
	# Conectar señal de detección de proximidad
	if area:
		area.body_entered.connect(_on_body_entered)
	
	# Añadir luz propia a la Sombra
	var self_light = OmniLight3D.new()
	self_light.light_color = Color(1.0, 0.0, 0.0)
	self_light.light_energy = 2.0
	self_light.omni_range = 5.0
	add_child(self_light)

	# Lifetime aleatorio
	max_lifetime = 60.0 # Darle suficiente tiempo para el diálogo de main.gd
	despawn_timer = max_lifetime
	
	# Animación de aparición
	current_alpha = 0.0
	var tween = create_tween()
	tween.tween_property(self, "current_alpha", 0.6, 2.0)
	
	# Enviar señal al journal (Presencia del vacío)
	var signal_idx = randi() % journal_signals_shadow.size()
	Global.add_signal(journal_signals_shadow[signal_idx])

	# Conectar al sistema de diálogo si es necesario para respuestas (Fallback)
	if not suppress_dialogue:
		if Global.dialogue_ui and not Global.dialogue_ui.option_selected.is_connected(_on_shadow_option):
			Global.dialogue_ui.option_selected.connect(_on_shadow_option)
	
func _process(delta):
	despawn_timer -= delta
	
	# Actualizar alpha del material
	if shadow_material:
		shadow_material.albedo_color.a = current_alpha
	
	# Movimiento sutil (flotante)
	position.y += sin(Time.get_ticks_msec() / 1000.0) * 0.2 * delta
	
	# Rotación lenta
	rotate_y(0.2 * delta)
	
	# Despawn cuando termine el tiempo
	if despawn_timer <= 0:
		despawn()
	
	# Fade out en los últimos 3 segundos
	if despawn_timer < 3.0:
		current_alpha = despawn_timer / 3.0 * 0.6

func set_player_reference(player):
	player_ref = player

func _on_body_entered(body):
	# Si el jugador se acerca, alejarse o desaparecer
	if body.is_in_group("player"):
		player_ref = body
		move_away_from_player()

func move_away_from_player():
	if player_ref:
		# Desaparecer rápidamente
		despawn_timer = min(despawn_timer, 2.0)

# --- INTERACTIVE DIALOGUE SYSTEM ---
func start_caterpillar_sequence(lines: Array):
	# Secuencia estilo "Oruga" (Palabras flotando independientemente)
	var height_offset = 0.0
	for line in lines:
		spawn_floating_word(line, height_offset)
		height_offset += 0.8 # Subir para la siguiente línea
		await get_tree().create_timer(1.5).timeout # Ritmo lento y psicodélico

	# Iniciar Diálogo Interactivo
	start_shadow_interaction()

func start_shadow_interaction():
	# Diálogo inicial de la sombra (Mandatory 3 arguments: speaker, name, text)
	Global.show_dialogue(self, "Sombra", "¿Quién... eres... tú?")
	
	# Opciones para el jugador (Mandatory 2 arguments: speaker, options)
	await get_tree().create_timer(2.0).timeout
	Global.show_options(self, ["Soy un usuario", "Soy código", "No lo sé"])

func _on_shadow_option(speaker, index):
	if speaker != self:
		return
	
	# Respuesta de la sombra a la elección del jugador
	if index == 0: # Usuario
		Global.show_dialogue(self, "Sombra", "Usuario... Visitante... Intruso.\nTu memoria es volátil.")
	elif index == 1: # Código
		Global.show_dialogue(self, "Sombra", "Código... Hermano... Error.\nNos parecemos.")
	elif index == 2: # No sé
		Global.show_dialogue(self, "Sombra", "La duda es el primer dato real.\nConsérvala.")
	
	# Marcar que el encuentro con la sombra ha terminado (para desbloquear quest de Dragona)
	Global.shadow_met_hint_given = true
	Global.current_quest_stage = Global.QuestStage.SHADOW_MET
	
	# Cerrar encuentro
	await get_tree().create_timer(1.5).timeout
	Global.hide_dialogue(self)
	despawn_timer = 2.0 # Iniciar despawn rápido

func spawn_floating_word(text: String, y_offset: float):
	# Solo spawneamos el label
	var label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 128 
	label.outline_size = 16
	label.modulate = Color(1, 0, 0, 0) # Empieza invisible
	label.text = text
	label.no_depth_test = true
	label.render_priority = 100
	label.position = Vector3(0, 2.0 + y_offset, 0) 
	add_child(label)
	
	# Animación: Fade In -> Flotar -> Fade Out
	var tw = create_tween()
	tw.tween_property(label, "modulate:a", 1.0, 1.0)
	tw.parallel().tween_property(label, "position:y", label.position.y + 0.5, 3.0)
	tw.tween_interval(2.0)
	tw.tween_property(label, "modulate:a", 0.0, 1.0)
	tw.tween_callback(label.queue_free)

func whisper():
	pass 

func despawn():
	# Animación de desaparición
	var tween = create_tween()
	tween.tween_property(self, "current_alpha", 0.0, 1.0)
	await tween.finished
	queue_free()
