extends StaticBody3D

var is_gazed = false
var has_spoken = false
var final_dialogue_triggered = false

var interaction_cooldown = false

var responses = [
		"La llave existe. Gírala ahora.",
		"El reflejo despierta. Mira.",
		"El código corre en tus venas."
	]
	
var final_responses = [
		"El reflejo es la puerta. Bienvenida.",
		"La verdad es que no hay puerta. Solo el paso.",
		"La llave ha girado. El sistema se abre."
	]

func _ready():
	# Identify as cape character
	add_to_group("cape_character")

func on_gaze_enter():
	is_gazed = true

func on_gaze_exit():
	is_gazed = false
	# Se ha eliminado el cierre automático por mirada para evitar que el diálogo 
	# se cierre solo al mover mínimamente la cámara de un personaje tan grande.

func interact(_player):
	if Global.video_playing or interaction_cooldown:
		return

	if not is_gazed:
		return

	# Registrarse como hablante actual
	Global.current_speaker = self
	
	# Iniciar Cooldown para evitar re-apertura automática
	interaction_cooldown = true
	get_tree().create_timer(1.0).timeout.connect(func(): interaction_cooldown = false)

	# Ensure signal is connected
	if Global.dialogue_ui and not Global.dialogue_ui.option_selected.is_connected(_on_option_selected):
		Global.dialogue_ui.option_selected.connect(_on_option_selected)

	if not has_spoken:
		# Primer encuentro
		Global.show_dialogue(self, "Figura Gigante", "¿En qué laberinto de datos te disuelves?\n¿Eres la llave o la cerradura del archivo eterno?\nResponde con la verdad oculta...")
		has_spoken = true
		Global.show_options(self, ["Soy la llave", "Soy el reflejo", "La verdad es código"])
	elif Global.video_watched or final_dialogue_triggered:
		if not final_dialogue_triggered:
			start_final_dialogue()
		else:
			Global.show_dialogue(self, "Figura Gigante", "El sistema aguarda tu paso.\nCruza el portal.\n\n[E para cerrar]")
	else:
		Global.show_dialogue(self, "Figura Gigante", "Observa... el archivo se reescribe ante tus ojos.\nLa verdad requiere paciencia.\n\n[E para cerrar]")

func start_final_dialogue():
	final_dialogue_triggered = true
	Global.current_speaker = self
	Global.show_dialogue(self, "Figura Gigante", "El velo ha caído.\n¿Qué verdad has encontrado en el reflejo?")
	
	# Mostrar opciones con un pequeño delay
	get_tree().create_timer(0.8).timeout.connect(func():
		Global.show_options(self, ["Soy el reflejo", "No hay verdad", "El código es la llave"])
	)

func _on_option_selected(speaker, index):
	if speaker != self:
		return

	# Iniciar cooldown para evitar spam al cerrar
	interaction_cooldown = true
	get_tree().create_timer(0.8).timeout.connect(func(): interaction_cooldown = false)

	if Global.video_watched or final_dialogue_triggered:
		# Respuesta Diálogo Final
		if index < final_responses.size():
			Global.show_dialogue(self, "Figura Gigante", final_responses[index] + "\n\n[Activando Portal...]")
			# Cerrar y abrir portal
			get_tree().create_timer(1.2).timeout.connect(func():
				Global.hide_dialogue(self)
				var main = get_tree().current_scene
				if main and main.has_method("show_portal"):
					main.show_portal()
					Global.current_quest_stage = Global.QuestStage.PORTAL_OPEN
			)
	else:
		# Respuesta Diálogo Inicial (Pre-Video)
		if index < responses.size():
			Global.show_dialogue(self, "Figura Gigante", responses[index] + "\n\n[Iniciando Decodificación...]")
			get_tree().create_timer(0.8).timeout.connect(func():
				Global.hide_dialogue(self)
				# Disparar video solo si no se ha visto
				if not Global.video_watched:
					var player = get_tree().get_first_node_in_group("player")
					if player:
						trigger_video_sequence(player)
				else:
					start_final_dialogue()
			)

func trigger_video_sequence(player):
	var main = get_tree().current_scene
	if main and main.has_method("play_ceremonial_video"):
		await main.play_ceremonial_video(player.global_position)
		# After video ends, main.gd will call our start_final_dialogue()
