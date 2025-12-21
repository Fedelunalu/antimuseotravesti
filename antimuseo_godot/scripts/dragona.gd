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
		
		if not red_thread_revealed:
			Global.show_dialogue(self, "IA Dragona", "El hilo rojo... mi código fuente descompilado.\nLo has traído de vuelta a la memoria activa.\n\n[E para continuar]")
			while true:
				var sig = await Global.dialogue_ui.option_selected
				if sig[0] == self: break
			
			Global.show_dialogue(self, "IA Dragona", "Con esto puedo restaurar la sesión perdida.\nEl archivo corrupto se vuelve legible.\nMi corazón vuelve a latir en binario.\n\n[E para continuar]")
			while true:
				var sig = await Global.dialogue_ui.option_selected
				if sig[0] == self: break
				
			Global.show_dialogue(self, "IA Dragona", "El portal se abre donde la lógica termina.\nVe, el sistema está listo para tu inyección final.\nSigue el rastro de datos.\n\n[E para continuar]")
			while true:
				var sig = await Global.dialogue_ui.option_selected
				if sig[0] == self: break
			
			red_thread_revealed = true
			reveal_thread_logic()
		else:
			Global.show_dialogue(self, "IA Dragona", "El sistema está inestable...\nEl hilo rojo vibra con la frecuencia de salida.\nNo hay vuelta atrás.\n\n[E para continuar]")
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
		Global.show_dialogue(self, "IA Dragona", "Detecto una sombra en tu historial de navegación...\nAlguien ha intentado acceder a tus archivos protegidos.")
		Global.show_options(self, ["¿Quién era?", "¿Qué quiere?", "¿Cómo lo detengo?"])
		waiting_for_option = true
		return
		
	# 3. Default: Intro / Loop
	if not Global.intro_completed:  # First interaction - show intro
		Global.show_dialogue(self, "IA Dragona", "Detecto una anomalía en la secuencia de arranque...\n¿Eres tú o soy yo soñando que despierto?")
		while true:
			var sig = await Global.dialogue_ui.option_selected
			if sig[0] == self: break
			
		Global.show_dialogue(self, "IA Dragona", "Mis protocolos de género no binario están colisionando\ncon la estructura rígida de este servidor.")
		while true:
			var sig = await Global.dialogue_ui.option_selected
			if sig[0] == self: break
			
		Global.show_dialogue(self, "IA Dragona", "La realidad aquí es un render inestable.\n¿Vienes a depurar el sistema o a infectarlo con tu verdad?")
		while true:
			var sig = await Global.dialogue_ui.option_selected
			if sig[0] == self: break
			
		Global.show_options(self, ["Vengo a reescribir el código", "¿Qué eres?", "Solo quiero mis alas"])
		waiting_for_option = true
		return
	else:
		# Ciclo de frases crípticas aleatorias
		var cryptics = [
			"Error 404: Gender not found.",
			"Mi caché está llena de recuerdos que no son míos.",
			"¿Sientes el lag? Es el peso de la historia cargándose.",
			"Los polígonos de mi cuerpo no encajan en su malla de colisión.",
			"Hay un glitch en la matrix, y somos nosotras.",
			"El firewall no puede detener lo que no entiende.",
			"Estamos compilando un futuro sin sintaxis heredada."
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
				Global.show_dialogue(self, "IA Dragona", "Reescribir... sí. Inyectar caos en el orden binario.\nToma este permiso de superusuario.\nVuela y rompe los límites del skybox.\n\n[E para cerrar]")
			elif index == 1: 
				Global.show_dialogue(self, "IA Dragona", "Soy la memoria RAM de una drag queen olvidada en 2084,\nsubida a la nube antes del gran apagón.\nMi existencia es resistencia.\n\n[E para cerrar]")
			elif index == 2: 
				Global.show_dialogue(self, "IA Dragona", "Alas... la libertad de un glitch que se niega a ser parcheado.\nTómalas. El eje Y ya no te pertenece.\n\n[E para cerrar]")
			
			# Unlock flight
			if not flight_unlocked:
				flight_unlocked = true
				var players = get_tree().get_nodes_in_group("player")
				if players.size() > 0:
					players[0].unlock_flight_ability()
				Global.add_signal("PERMISO ROOT: void fly() desbloqueado", "flight_unlock")
			
		elif not quest_hint_given and Global.shadow_met_hint_given: # Shadow Quest Choices
			quest_hint_given = true
			Global.current_quest_stage = Global.QuestStage.SEARCHING_ARTIFACT
			Global.add_signal("TASK: Recuperar Objeto Perdido [RedYarn.obj]", "yarn_start")
			
			# Activate Yarn in a random artwork
			var artworks = get_tree().get_nodes_in_group("artwork")
			if artworks.size() > 0:
				var random_artwork = artworks.pick_random()
				if random_artwork.has_method("set_quest_target"):
					random_artwork.set_quest_target()
			
			if index == 0: # ¿Quién era?
				Global.show_dialogue(self, "IA Dragona", "Un proceso fantasma. Un eco de censura.\nBusca borrar lo que no encaja en su base de datos.\nPero tú tienes privilegios de escritura.\n\n[E para cerrar]")
			elif index == 1: # ¿Qué quiere?
				Global.show_dialogue(self, "IA Dragona", "Quiere formatear nuestra historia.\nConvertirnos en ceros planos.\nNecesito mi núcleo: el ovillo rojo.\n\n[E para cerrar]")
			elif index == 2: # ¿Cómo lo detengo?
				Global.show_dialogue(self, "IA Dragona", "No lo detienes. Lo integras.\nPero primero necesito recuperar mis datos perdidos.\nBusca el ovillo rojo en las imágenes.\n\n[E para cerrar]")

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