extends StaticBody3D

@onready var mesh = $MeshInstance3D if has_node("MeshInstance3D") else null
@onready var audio_player = $AudioStreamPlayer3D if has_node("AudioStreamPlayer3D") else null

var texture_path: String = ""
var is_gazed = false
var artwork_descriptions: Dictionary = {}

func _ready():
	# Cargar descripciones una sola vez
	if artwork_descriptions.is_empty():
		load_artwork_descriptions()
	
	if mesh:
		var has_texture = false
		if not texture_path.is_empty():
			var texture = load(texture_path)
			if texture:
				var material = StandardMaterial3D.new()
				material.albedo_texture = texture
				material.emission_enabled = true
				material.emission = Color(1, 1, 1) * 0.05
				material.emission_texture = texture
				material.metallic = 0.1
				material.roughness = 0.7
				mesh.material_override = material
				has_texture = true
		
		if not has_texture:
			# Fallback color for web when load fails
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(randf(), randf(), randf(), 1.0)
			material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
			mesh.material_override = material
	
	# Agregar al grupo de obras de arte
	add_to_group("artwork")

func load_artwork_descriptions():
	var json_path = "res://artwork_descriptions.json"
	var file = FileAccess.open(json_path, FileAccess.READ)
	if file:
		var json = JSON.new()
		json.parse(file.get_as_text())
		artwork_descriptions = json.get_data() if json.get_data() is Dictionary else {}
	else:
		print("Warning: No artwork descriptions file found at ", json_path)

func set_texture_path(path: String):
	texture_path = path

func on_gaze_enter():
	is_gazed = true
	# Solo mostrar prompt de interacción, sin descripción
	print("👁️ MIRADO: ", name)
	if audio_player:
		audio_player.play()

func on_gaze_exit():
	is_gazed = false
	print("👁️ DEJADO: ", name)
	Global.hide_dialogue(self)
	if audio_player:
		audio_player.stop()

var is_quest_target = false

func interact(_player = null):
	if is_gazed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		print("📸 INTERACTUANDO CON: ", name, " | Conteo: ", Global.shadow_interaction_count + 1)
	# Lógica de Quest: Fragmento Brillante (Ovillo)
		if is_quest_target:
			# SOLO permitir recoger si estamos buscando activamente (después de hablar con Dragona)
			if Global.current_quest_stage == Global.QuestStage.SEARCHING_ARTIFACT:
				# Recoger ovillo
				if has_node("YarnSphere"):
					$YarnSphere.queue_free()
					Global.has_yarn = true
					
				Global.current_quest_stage = Global.QuestStage.ARTIFACT_FOUND
				Global.show_dialogue(self, "", "El ovillo late contra tu palma,\nsaturado de memorias no dichas.\nSu calor es la canción incompleta de la dragona,\nla melodía que une mundos separados por tiempo y código.\n\n[E para continuar]")
				# Don't hide automatically - player must press E to continue
				Global.add_signal("OVILLO DE MEMORIA RECUPERADO", "artifact_found")
				Global.add_signal("...la dragona aguarda tu retorno...", "clue_dragona")
				
				# Efecto visual al encontrarlo
				if has_node("QuestParticles"):
					$QuestParticles.emitting = true
				return

		# Texto críptico y ambiguo standard (si no es quest o ya se encontró)
		var _artwork_name = texture_path.get_file().get_basename()
		var cryptic_text = generate_cryptic_fragment()
		Global.show_dialogue(self, "", cryptic_text)
		_play_interaction_feedback()
		
		# Agregar fragmento visual al journal
		Global.add_fragment(texture_path, _artwork_name)
		
		# Incrementar contador GLOBAL de interacciones
		Global.shadow_interaction_count += 1
		print("📝 FRAGMENTO AGREGADO: ", _artwork_name, " (Total Global: ", Global.shadow_interaction_count, ")")
		
		# 10% de probabilidad de generar una señal críptica
		if randf() < 0.1:
			var signal_text = generate_signal()
			Global.add_signal(signal_text)
			
		# Sombra Trigger Logic: Al llegar a 5 o más interacciones GLOBALES
		# Trigger solo una vez
		print("🔍 Verificando Shadow: global_count=", Global.shadow_interaction_count, " spawned=", Global.shadow_spawned)
		
		if Global.shadow_interaction_count >= 5 and not Global.shadow_spawned:
			Global.shadow_spawned = true
			print("🚨🚨🚨 ¡CONDICIÓN DE SHADOW ALCANZADA! Triggering...")
			var main = get_tree().current_scene
			if main and main.has_method("spawn_shadow"):
				print("✅ main.spawn_shadow() encontrado - EJECUTANDO")
				Global.add_signal("⚠️ ALERTA DE SEGURIDAD: Límite de memoria alcanzado.", "shadow_warning")
				_play_shadow_warning_effect(_player) # Pass the player here
				await get_tree().create_timer(1.0).timeout
				print("🔴 LLAMANDO spawn_shadow() ahora...")
				main.spawn_shadow()
				print("🔴 spawn_shadow() completado")
			else:
				print("❌ main.spawn_shadow() NO encontrado o main es null")
		elif Global.shadow_spawned:
			print("⚠️ Shadow ya fue triggereado anteriormente")
		
		# Reproducir sonido si está disponible
		if audio_player:
			audio_player.play()

func set_quest_target():
	is_quest_target = true
	# Añadir brillo visual (inicialmente oculto o tenue)
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.2, 0.4) # Rojo rosado
	light.omni_range = 3.0
	light.light_energy = 0.0 # Apagado inicialmente
	light.name = "QuestLight"
	add_child(light)
	
	# Añadir Esfera Roja (El Ovillo) - Más pequeña
	var yarn = MeshInstance3D.new()
	yarn.name = "YarnSphere"
	var sphere = SphereMesh.new()
	sphere.radius = 0.15 # Reducido
	sphere.height = 0.3
	yarn.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.1, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.0, 0.2)
	mat.emission_energy_multiplier = 2.0
	yarn.material_override = mat
	
	yarn.position = Vector3(0, 0, 0.5) 
	yarn.visible = false # Oculto por defecto
	add_child(yarn)
	
	# Partículas sutiles
	var particles = CPUParticles3D.new()
	particles.name = "QuestParticles"
	particles.amount = 20
	particles.lifetime = 1.0
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.5
	particles.gravity = Vector3(0, 0, 0)
	particles.color = Color(1.0, 0.2, 0.4)
	particles.emitting = false # Apagado
	add_child(particles)

func _process(_delta):
	# Make artworks float gently up and down
	# ... (lógica flotante existente manejada por animation o externa, aqui solo rotamos si queremos o dejamos que parent lo haga)
	# El spawner maneja el movimiento del parent node, este script maneja interaction.
	
	# Lógica de Visibilidad Quest (Cada frame chequear estado)
	if is_quest_target:
		var show_quest = (Global.current_quest_stage == Global.QuestStage.SEARCHING_ARTIFACT)
		
		var yarn = get_node_or_null("YarnSphere")
		if yarn and yarn.visible != show_quest:
			yarn.visible = show_quest
			
			if has_node("QuestLight"):
				$QuestLight.light_energy = 2.0 if show_quest else 0.0
				
			if has_node("QuestParticles"):
				$QuestParticles.emitting = show_quest

func _on_area_3d_input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		# Verificar si es la pieza de la quest (ovillo rojo)
		if texture_path == "res://assets/red_yarn.png":
			if Global.current_quest_stage == Global.QuestStage.SEARCHING_ARTIFACT:
				# Recoger ovillo
				if has_node("YarnSphere"):
					$YarnSphere.queue_free()
					Global.has_yarn = true
					
				Global.current_quest_stage = Global.QuestStage.ARTIFACT_FOUND
				Global.show_dialogue(self, "", "El ovillo late contra tu palma,\nsaturado de memorias no dichas.\nSu calor es la canción incompleta de la dragona,\nla melodía que une mundos separados por tiempo y código.\n\n[E para continuar]")
				# Don't hide automatically - player must press E to continue
				Global.add_signal("OVILLO DE MEMORIA RECUPERADO", "artifact_found")
				Global.add_signal("...la dragona aguarda tu retorno...", "clue_dragona")
				
				# Efecto visual al encontrarlo
				if has_node("QuestParticles"):
					$QuestParticles.emitting = true
				return

		# Texto críptico y ambiguo standard (si no es quest o ya se encontró)
		var _artwork_name = texture_path.get_file().get_basename()
		var cryptic_text = generate_cryptic_fragment()
		Global.show_dialogue(self, "", cryptic_text)

func generate_cryptic_fragment() -> String:
	# Obtener el nombre del archivo de textura
	var filename = texture_path.get_file()
	
	# Buscar en el diccionario de descripciones
	if artwork_descriptions.has(filename):
		return artwork_descriptions[filename]
	
	# Si no hay descripción, usar fragmentos genéricos
	var cryptic_fragments = [
		"esto no es lo que ves\npero tampoco es otra cosa",
		"¿quién puso esto acá?\n¿quién te puso a vos?",
		"memoria visual\no visual memorable\n¿hay diferencia?",
		"imagen que mira\nmirada que imagina",
		"¿es arte?\n¿es pregunta?\n¿es respuesta?",
		"lo que fue\nlo que es\nlo que será\ntodo es ahora",
		"píxeles y pigmentos\ndatos y deseos\n¿misma cosa?",
		"capturaron un momento\nel momento los capturó",
		"¿documento o ficción?\n¿importa?",
		"en cada obra\nun mundo\nen cada mundo\nuna obra"
	]
	
	return cryptic_fragments[randi() % cryptic_fragments.size()]

func generate_signal() -> String:
	var signals = [
		"LOG: Renderizado visual completado.",
		"BUFFER: Memoria de texturas al 80%.",
		"WARNING: Interpretación no definida en 'artwork_data'.",
		"DEBUG: [visual_buffer.read()] -> Éxito.",
		"ERROR: Ambigüedad detectada en píxel (404, 202)."
	]
	
	return signals[randi() % signals.size()]

func _play_interaction_feedback():
	if mesh and mesh.material_override is StandardMaterial3D:
		var material = mesh.material_override
		var original_emission_energy = material.emission_energy_multiplier
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		# Animate to a brighter emission
		tween.tween_property(material, "emission_energy_multiplier", original_emission_energy + 2.0, 0.15)
		# Animate back to original
		tween.tween_property(material, "emission_energy_multiplier", original_emission_energy, 0.5)

func _play_shadow_warning_effect(player_node: Node3D):
	if not player_node:
		return
	
	# Create a simple light effect instead of particles
	var warning_light = OmniLight3D.new()
	warning_light.light_color = Color(0.1, 0.1, 0.1)  # Dark gray/black
	warning_light.light_energy = 1.0  # Reduced from 2.0
	warning_light.omni_range = 3.0   # Reduced from 5.0
	
	# Position the light near the player
	warning_light.position = Vector3(0, 1.0, 0)  # Use local position instead
	
	# Add light to the scene
	get_tree().current_scene.add_child(warning_light)
	
	# Create a simple glow effect with a Tween
	var tween = create_tween()
	tween.set_loops(2)  # Reduced from 3 loops
	tween.tween_property(warning_light, "light_energy", 2.0, 0.2)
	tween.tween_property(warning_light, "light_energy", 1.0, 0.2)
	
	# Remove light after effect completes
	await get_tree().create_timer(1.0).timeout  # Reduced from 1.5 seconds
	warning_light.queue_free()
	
	# Trigger screen shake
	var main = get_tree().current_scene
	if main and main.has_method("_apply_screen_shake"):
		main._apply_screen_shake(0.1, 0.15) # Reduced intensity from 0.2, 0.3
