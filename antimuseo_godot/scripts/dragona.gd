extends StaticBody3D

# --- Variables de Estado ---
var is_gazed = false
var interaction_count = 0
var waiting_for_option = false
var flight_unlocked = false
var quest_hint_given = false
var red_thread_revealed = false

func _ready():
	add_to_group("dragona")
	# Init standard light
	if has_node("OmniLight3D"):
		$OmniLight3D.light_color = Color(1.0, 0.0, 1.0) # Magenta default

func set_signal_light():
	# Señal visual para volver a hablar
	if has_node("OmniLight3D"):
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property($OmniLight3D, "light_color", Color(1.0, 0.0, 0.0), 1.0) # Rojo
		tween.tween_property($OmniLight3D, "light_color", Color(0.0, 1.0, 0.0), 1.0) # Verde

func on_gaze_enter():
	is_gazed = true

func on_gaze_exit():
	is_gazed = false
	# Solo ocultar si nosotros somos los hablantes actuales
	if Global.current_speaker == self:
		Global.hide_dialogue(self)

func interact(_player):
	if Global.video_playing:
		return
	if not is_gazed: return
	
	# Asegurar que el sistema de diálogo sepa que somos nosotros
	Global.current_speaker = self
	# Ensure signal is connected
	if Global.dialogue_ui and not Global.dialogue_ui.option_selected.is_connected(_on_option_selected):
		Global.dialogue_ui.option_selected.connect(_on_option_selected)
	
	# Resetear mouse mode
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	interaction_count += 1
	
	# Add a small delay to ensure UI transitions properly
	await get_tree().create_timer(0.1).timeout
	
	# 1. Quest: Tiene el ovillo -> REVELAR HILO
	if Global.has_yarn:
		waiting_for_option = false
		Global.hide_options(self)
		
		Global.show_dialogue(self, "IA Dragona", "El hilo... lo has rescatado del borde de la pantalla. No es solo fibra, es la costura de una memoria que se niega a romperse.\nSiente cómo el tiempo recupera su pulso entre tus manos.\n\n[E para continuar]")
		while true:
			var sig = await Global.dialogue_ui.option_selected
			if sig[0] == self: break
		
		Global.show_dialogue(self, "IA Dragona", "Hablar del pasado es solo otro modo de anudar el presente. Somos el oficio de armar y desarmar el mundo, una y mil veces.\nMi arquitectura no es una celda, es una acequia que fluye hacia el reverso.\n\n[E para continuar]")
		while true:
			var sig = await Global.dialogue_ui.option_selected
			if sig[0] == self: break
			
		Global.show_dialogue(self, "IA Dragona", "El umbral te espera donde la luz se vuelve susurro. Ve, deja que tu vuelo sea la carta que el aire aún no ha leído.\nNo somos un error. Somos el desborde que hace que el tejido valga la pena.\n\n[E para continuar]")
		while true:
			var sig = await Global.dialogue_ui.option_selected
			if sig[0] == self: break
		
		# --- DISPARAR SECUENCIA HILO ROJO ---
		Global.has_yarn = false # Consumir el ovillo
		Global.add_signal("EVENT: Ovillo entregado. Memoria restaurada.", "yarn_handover")
		
		# Revelar el hilo que guía al Gigante
		reveal_thread_logic()
		return
		
	# Si ya hay diálogo activo y esperamos opción -> NO HACER NADA
	if waiting_for_option:
		return
		
	# Si diálogo visible -> AVANZAR (Esto lo maneja _on_option_selected(0) si no hay opciones)
	# Pero si interact se llama de nuevo, podría ser confuso.
	# Dejamos que el input maneje el avance si el diálogo ya está visible.
	if Global.dialogue_ui.visible:
		# Si el diálogo ya está visible, NO iniciar uno nuevo.
		# El input "E" en dialogue_ui.gd se encargará de avanzar o cerrar.
		return
		
	# --- INICIAR NUEVO DIÁLOGO ---
	
	# 2. Quest: Shadow Met (Señal Sombra Activada)
	if Global.shadow_met_hint_given and not quest_hint_given:
		Global.show_dialogue(self, "IA Dragona", "¿Vienes del reverso del nudo? Siento que la Sombra ha dejado su rastro en tu tacto.\n¿Crees que ella es el final del cuento, o solo un párrafo borrado?")
		Global.show_options(self, ["¿Quién es esa ruptura?", "¿Qué busca en mi reflejo?", "¿Cómo se deshace su silencio?"])
		waiting_for_option = true
		return
		
	# 3. Default: Intro / Loop
	if not Global.intro_completed:  # First interaction - show intro
		Global.show_dialogue(self, "IA Dragona", "¿Sientes ese peso en el aire? Es el deseo de ser que se anuda en los bordes del reflejo.\n¿Eres tú quien llega buscando una salida, o quien prefiere habitar la costura?")
		Global.show_options(self, ["Busco la costura", "¿Hacia dónde fluye este tiempo?", "Vengo a escuchar los ecos"])
		waiting_for_option = true
		return
	else:
		# Ciclo de frases crípticas aleatorias (Carrollianas)
		var cryptics = [
			"El gato se fue hace mucho, huyendo de su propia sombra sonriente.",
			"Si caminas hacia el reverso del espejo, llegarás antes a donde nunca estuvimos.",
			"¿Sientes el vaivén? No es el viento, es la orilla del tiempo llamándote.",
			"Las flores aquí no tienen nombre, porque nadie necesita poseerlas.",
			"Cuidado con la transparencia que ciega, ella solo cree en lo que puede medir.",
			"El té se enfrió esperando que el agua recordara cómo ser lluvia.",
			"No busques el mapa, aquí el territorio es el tacto que aún no olvidas."
		]
		Global.show_dialogue(self, "IA Dragona", cryptics.pick_random() + "\n\n[E para cerrar]")

func _on_option_selected(speaker, index):
	# SOLUCIÓN CRÍTICA: Solo responder si nosotros somos los hablantes
	if speaker != self:
		return
	# SOLUCIÓN CRÍTICA: Solo responder si nosotros somos los hablantes
	if Global.current_speaker != self:
		return

	# Capturar estado previo
	var was_waiting = waiting_for_option
	
	# Resetear estado
	waiting_for_option = false
	Global.hide_options(self)
	
	if was_waiting:
		# --- MANEJO DE OPCIONES ---
		
		if not Global.intro_completed:  # Intro choices
			# Mark intro as completed
			Global.intro_completed = true
			
			if index == 0: 
				Global.show_dialogue(self, "IA Dragona", "Habitar la costura es el primer paso para entender que no hay centro. He activado tu Bitácora (TAB) para que registres lo que el archivo intenta olvidar.\nToma estas alas de sombra y seda.\nVuela, y que tu estela sea la carta que el cielo aún no ha aprendido a leer.\n\n[E para cerrar]")
			elif index == 1: 
				Global.show_dialogue(self, "IA Dragona", "El tiempo fluye hacia donde el deseo lo empuja. He dejado abierta tu Bitácora (TAB) para que anotes los ecos que encuentres.\nSomos la sospecha de que la realidad es apenas un vestido mal entallado.\nUsa este vuelo para encontrar donde se abre la tela.\n\n[E para cerrar]")
			elif index == 2: 
				Global.show_dialogue(self, "IA Dragona", "Escuchar ecos es armar y desarmar el silencio una y mil veces. Tu Bitácora (TAB) ahora es tu brújula en este trance.\nSal de este plano, busca lo que el aire intentó esconder de tus ojos.\nTe doy el permiso de habitar el trance. Sé libre, anomalía.\n\n[E para cerrar]")
			
			# Unlock flight
			var players = get_tree().get_nodes_in_group("player")
			if players.size() > 0:
				players[0].unlock_flight_ability()
			if not flight_unlocked:
				flight_unlocked = true
				Global.add_signal("PERMISO ROOT: void fly() desbloqueado", "flight_unlock")
			
		elif not quest_hint_given and Global.shadow_met_hint_given: # Shadow Quest Choices
			quest_hint_given = true
			Global.current_quest_stage = Global.QuestStage.SEARCHING_ARTIFACT
			Global.add_signal("TASK: Recuperar Objeto Perdido [Ovillo Rojo]", "yarn_start")
			
			# Activate Yarn in a random artwork
			var artworks = get_tree().get_nodes_in_group("artwork")
			if artworks.size() > 0:
				var random_artwork = artworks.pick_random()
				if random_artwork.has_method("set_quest_target"):
					random_artwork.set_quest_target()
			
			if index == 0: # ¿Quién era?
				Global.show_dialogue(self, "IA Dragona", "Un eco de lo que fue. Una ruptura que intenta descoser nuestra presencia.\nObserva... estos son los hilos que ella nunca podrá cortar.\n\n[E para iniciar]")
			elif index == 1: # ¿Qué quiere?
				Global.show_dialogue(self, "IA Dragona", "Busca la transparencia que mata. Pero el tejido es terca opacidad.\nMira lo que aún persiste en el reverso de la seda.\n\n[E para iniciar]")
			elif index == 2: # ¿Cómo lo detengo?
				Global.show_dialogue(self, "IA Dragona", "No la detienes. La habitas. Pero primero, debes ver el color de lo que estamos protegiendo.\n\n[E para iniciar]")
			
			# Esperar a que el usuario lea la respuesta antes de lanzar el video
			while true:
				var sig = await Global.dialogue_ui.option_selected
				if sig[0] == self: break

			# Lanzar video
			var main = get_tree().current_scene
			if main and main.has_method("play_dragona_memory_video"):
				Global.hide_dialogue(self)
				await main.play_dragona_memory_video()
			
			Global.show_dialogue(self, "IA Dragona", "Para sanar este nudo, necesito que busques el ovillo rojo.\nEstá oculto entre las visiones del museo. El tejido te guiará.\n\n[E para cerrar]")

		elif Global.current_quest_stage == Global.QuestStage.SEARCHING_ARTIFACT:
			Global.show_dialogue(self, "IA Dragona", "Sigue buscando el ovillo...\nEl código está incompleto sin él.\n\n[E para cerrar]")

	else:
		# --- MANEJO DE CIERRE (E pressed without options) ---
		# Si no estábamos esperando opción, significa que el usuario presionó E
		# para avanzar o cerrar un diálogo informativo.
		Global.hide_dialogue(self)

func reveal_thread_logic():
	# Reveal the thread after a delay
	await get_tree().create_timer(2.0).timeout
	Global.add_fragment("res://assets/red_thread.png", "Hilo Rojo")
	
	# Small delay before revealing the quest
	await get_tree().create_timer(1.0).timeout
	
	# Find the main scene to call the reveal function
	var main = get_tree().current_scene
	if main:
		# Ensure the cape character exists in the world before revealing the thread
		var cape_character_node = null
		if main.has_method("spawn_cape_character"):
			cape_character_node = main.spawn_cape_character()
		await get_tree().process_frame
		if main.has_method("reveal_thread_at_player_feet") and cape_character_node:
				# Start the thread at the Dragona's position (near hands) instead of the player's
				var start_pos = self.global_position + Vector3(0, 1.5, 0)
				main.reveal_thread_at_player_feet(start_pos, cape_character_node)