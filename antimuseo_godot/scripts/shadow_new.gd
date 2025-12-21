extends Node3D

var player_ref = null

# Palabras/códigos que flotan estilo "Oruga Fumadora"
var floating_words = [
	"TRANSFORMACIÓN",
	"MEMORIA ARDIENTE",
	"¿QUIÉN SOY?",
	"IDENTIDAD FLUIDA",
	"ERROR SISTEMA",
	"DATO VIVIENTE",
	"CONSCIENCIA TEXTIL",
	"PRESENCIA DIGITAL",
	"ECO TEMPORAL",
	"¿YO VERDADERO?",
	"FRACTAL IDENTIDAD",
	"SUEÑO COLECTIVO",
	"CÓDIGO AFECTIVO",
	"CUERPO ARCHIVADO",
	"GLITCH CONSCIENTE",
	"VACÍO LLENADOR",
	"CORRUPCIÓN CREATIVA",
	"REALIDAD TEJIDA"
]

func _ready():
	print("🔴 SOMBRA APARECIDA EN POSICIÓN: ", global_position)
	print("⚫ INICIANDO SECUENCIA DE APAGÓN")
	
	# Guardar referencia del jugador
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
	
	# Iniciar secuencia completa
	await start_shadow_encounter()

func start_shadow_encounter():
	# 1. Iniciar apagón en paralelo (no esperar a que termine los 20s)
	var main = get_tree().current_scene
	if main and main.has_method("trigger_glitch_effect"):
		print("⚫ INICIANDO APAGÓN EN PARALELO")
		main.trigger_glitch_effect()  # No awaitar - continúa en paralelo
	else:
		print("⚠️ trigger_glitch_effect no encontrado")
	
	# 2. Esperar a que apagón se establezca (primeros 0.5 segundos)
	await get_tree().create_timer(0.5).timeout
	
	# 3. Generar palabras flotantes durante oscuridad
	print("✨ GENERANDO PALABRAS FLOTANTES")
	spawn_floating_words_sequence()
	
	# 4. Esperar a que terminen las palabras (6 segundos)
	await get_tree().create_timer(6.0).timeout
	
	# 5. Mostrar opciones de respuesta
	print("💬 MOSTRANDO OPCIONES DE RESPUESTA")
	await show_dialogue_options()

func spawn_floating_words_sequence():
	# Generar 10-15 palabras flotantes en secuencia
	var num_words = randi_range(10, 15)
	
	for i in range(num_words):
		var word = floating_words[randi() % floating_words.size()]
		var spawn_pos = Vector3(
			randf_range(-20, 20),
			randf_range(0.5, 12),
			randf_range(-20, 20)
		)
		
		spawn_floating_word_3d(word, spawn_pos)
		await get_tree().create_timer(0.3).timeout

func spawn_floating_word_3d(text: String, start_pos: Vector3):
	var label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = randi_range(80, 160)
	label.outline_size = 12
	label.text = text
	label.no_depth_test = true
	label.render_priority = 100
	label.position = start_pos
	
	# Color rojo parpadeante
	label.modulate = Color(1, 0, 0, 0)
	
	add_child(label)
	
	print("✨ Palabra flotante creada: ", text, " en ", start_pos)
	
	# Animación completa
	var duration = randf_range(7.0, 10.0)
	
	# Fade in rápido
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.85, 1.0)
	
	# Flotación suave hacia arriba (paralelo)
	var tween2 = create_tween()
	tween2.tween_property(label, "position:y", start_pos.y + randf_range(4, 8), duration)
	
	# Rotación en XY (paralelo)
	var tween3 = create_tween()
	tween3.set_parallel(true)
	tween3.tween_property(label, "rotation:y", TAU * randf_range(2, 4), duration)
	tween3.tween_property(label, "rotation:x", randf_range(-0.5, 0.5), duration)
	
	# Parpadeo rojo - SIN LOOPS infinitos (calcular iteraciones)
	var blink_count = int(duration / 0.4)
	var blink_tween = create_tween()
	for _i in range(blink_count):
		if is_instance_valid(label):
			blink_tween.tween_property(label, "modulate:r", 0.4, 0.2)
			blink_tween.tween_property(label, "modulate:r", 1.0, 0.2)
	
	# Fade out y cleanup - DESPUÉS de duration
	await get_tree().create_timer(duration).timeout
	
	if is_instance_valid(label):
		var fade = create_tween()
		fade.tween_property(label, "modulate:a", 0.0, 1.5)
		fade.tween_callback(func(): 
			if is_instance_valid(label):
				label.queue_free()
		)

func show_dialogue_options():
	var invocation = "¿Me oyes? Soy el eco de quienes no fueron escuchados...\nLa dragona siente tu presencia,\nsu corazón late en sincronía con la tuya."
	Global.show_dialogue(self, "Sombra", invocation)
	await get_tree().create_timer(4.5).timeout
	
	var weaving = "Viniste buscando conexiones...\nPero las verdaderas conexiones\nrequieren sacrificio, memoria, dolor compartido.\nLa dragona guarda la llave de esa conexión."
	Global.show_dialogue(self, "Sombra", weaving)
	await get_tree().create_timer(4.5).timeout
	
	var pulse = "Responde. Tu elección reverberará\nen los hilos que unen este mundo con el tuyo.\n¿Qué deseas encontrar en el corazón de la dragona?"
	Global.show_dialogue(self, "Sombra", pulse)
	await get_tree().create_timer(3.5).timeout
	
	var options = [
		"La verdad sobre mi existencia",
		"La conexión con quienes vinieron antes",
		"El camino hacia la transformación"
	]
	
	print("💬 Mostrando opciones - ESPERANDO RESPUESTA DEL JUGADOR")
	Global.show_options(self, options)
	
	var choice = -1
	if Global.dialogue_ui:
		choice = await Global.dialogue_ui.option_selected
		print("🎯 Jugador eligió opción: ", choice)
	else:
		await get_tree().create_timer(4.0).timeout
	
	var response = ""
	match choice:
		0:
			response = "Tu existencia es un fractal...\ncada iteración contiene\nlas semillas de todas las demás.\nLa dragona te ayudará a ver el patrón completo."
		1:
			response = "En su corazón tejido hallarás\ntodas las voces que fueron silenciadas.\nElla es el puente entre generaciones,\nentre lo que fue y lo que puede ser."
		2:
			response = "La transformación requiere\nromper la piel de la realidad.\nLa dragona guarda el hilo que,\nal tirar de él, desgarra la ilusión\nde la separación entre mundos."
		_:
			response = "Incluso el silencio es una respuesta...\nuna pausa en la melodía\nde conexiones que esperan ser tejidas."
	
	Global.show_dialogue(self, "Sombra", response)
	await get_tree().create_timer(5.0).timeout
	
	Global.show_dialogue(self, "Sombra", "Sigue el hilo rojo que late con vida propia.\nRespira profundo y deja que tu cuerpo recuerde el camino.\nAllí donde el tiempo se dobla sobre sí mismo,\nla figura que espera ya conoce tu nombre.")
	await get_tree().create_timer(4.0).timeout
	
	Global.add_signal("⚠️ ANOMALÍA ENCUENTRADA", "shadow_encounter_log")
	Global.add_signal("👁️ SIGUE EL HILO ROJO", "shadow_guidance")
	
	# Make sure to hide options after dialogue completion
	Global.hide_dialogue(self)
	await get_tree().create_timer(1.0).timeout
	print("🔴 SOMBRA DESAPARECIENDO")
	queue_free()

func _process(_delta):
	pass
	pass
