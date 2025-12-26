extends Control

@onready var tab_container = $Panel/TabContainer
@onready var text_area = $Panel/TabContainer/TuEscritura/TextEdit
@onready var fragments_container = $Panel/TabContainer/FragmentosVisuales/ScrollContainer/VBoxContainer
@onready var signals_container = $Panel/TabContainer/Señales/ScrollContainer/VBoxContainer
@onready var signal_notification = $SignalNotification if has_node("SignalNotification") else null

var journal_data = {
	"entries": [],
	"fragments": [],
	"signals": []
}

var save_path = "user://journal.json"
var new_signal_available = false

func _ready():
	visible = false
	Global.journal = self
	load_data()
	
	# --- DEVELOPMENT MODE: FORCE RESET ---
	# Reiniciar diario en cada ejecución para probar flujo narrativo limpio
	journal_data = {
		"entries": [],
		"fragments": [],
		"signals": []
	}
	save_data()
	# -------------------------------------
	
	# Texto inicial críptico
	if journal_data.entries.is_empty():
		text_area.text = "¿estoy escribiendo?\n¿o me están escribiendo?\n\n"
	else:
		text_area.text = "\n".join(journal_data.entries)
	
	# Renderizar fragmentos y señales existentes
	refresh_fragments()
	refresh_signals()
	
	# Verificar milestones iniciales (por si acaso)
	check_fragment_milestones()
	
	# --- BOTÓN DESCARGAR ---
	_setup_download_button()

func _setup_download_button():
	var btn = Button.new()
	btn.text = "📥 Descargar Bitácora (.txt)"
	btn.position = Vector2(10, 550) # Esquina inferior izquierda del panel
	btn.custom_minimum_size = Vector2(200, 40)
	btn.tooltip_text = "Guarda tus memorias en un archivo externo"
	btn.pressed.connect(download_journal)
	$Panel.add_child(btn)

func download_journal():
	var file_content = "=== BITÁCORA DEL ANTIMUSEO TRAVESTI ===\n"
	file_content += "Fecha: " + Time.get_datetime_string_from_system() + "\n\n"
	
	file_content += "--- TUS ESCRITOS ---\n"
	file_content += text_area.text + "\n\n"
	
	file_content += "--- FRAGMENTOS VISUALES RECOGIDOS ---\n"
	for frag in journal_data.fragments:
		file_content += "- " + frag.name + " (" + frag.image + ")\n"
	
	file_content += "\n--- SEÑALES DEL SISTEMA ---\n"
	for sig in journal_data.signals:
		file_content += "[" + str(int(sig.timestamp) % 10000) + "] " + sig.text + "\n"
	
	file_content += "\n=== FIN DEL REGISTRO ==="
	
	# Detectar plataforma
	if OS.has_feature("web"):
		# WEB: Usar JavaScript para descargar
		var js_code = """
		var blob = new Blob([UTF8ToString($0)], {type: 'text/plain'});
		var url = URL.createObjectURL(blob);
		var a = document.createElement('a');
		a.href = url;
		a.download = 'bitacora_antimuseo.txt';
		a.click();
		URL.revokeObjectURL(url);
		"""
		JavaScriptBridge.eval(js_code.replace("$0", str(file_content.to_utf8_buffer())))
		print("💾 Bitácora descargada (Web) - Revisa tu carpeta de Descargas")
		_show_download_confirmation("Tu memoria ha sido extraída del archivo.\nRevisa tu carpeta de Descargas.")
	else:
		# DESKTOP: Usar user:// (siempre tiene permisos)
		var path = "user://bitacora_antimuseo.txt"
		var file = FileAccess.open(path, FileAccess.WRITE)
		if file:
			file.store_string(file_content)
			file.close()
			var real_path = ProjectSettings.globalize_path(path)
			print("💾 Bitácora descargada en: ", real_path)
			_show_download_confirmation("Tu memoria ha sido extraída del archivo.\nGuardada en: " + real_path.get_file())
		else:
			print("❌ Error al guardar bitácora")
			_show_download_confirmation("El archivo resistió la extracción.\nIntenta copiar el texto manualmente.")

func _show_download_confirmation(message: String):
	# Crear label flotante que no tape la bitácora
	var confirm_label = Label.new()
	confirm_label.text = message
	confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_label.add_theme_font_size_override("font_size", 18)
	confirm_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.7))
	confirm_label.position = Vector2(400, 20)  # Arriba, no tapa el botón
	confirm_label.size = Vector2(480, 80)
	confirm_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	$Panel.add_child(confirm_label)
	
	# Fade out después de 3 segundos
	var tween = create_tween()
	tween.tween_property(confirm_label, "modulate:a", 0.0, 1.0).set_delay(2.0)
	tween.tween_callback(confirm_label.queue_free)

func _input(event):
	# Toggle journal con TAB - SIEMPRE debe funcionar
	if event.is_action_pressed("toggle_journal"):
		visible = !visible
		if visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			text_area.grab_focus()
			new_signal_available = false
			if signal_notification:
				signal_notification.visible = false
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			# save_journal() 

# Asegurar que el mouse se mantenga visible si el journal está abierto
func _process(_delta):
	if visible and Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func add_fragment(image_path: String, fragment_name: String):
	# Evitar duplicados revisando si la imagen ya existe
	for frag in journal_data.fragments:
		if frag.image == image_path:
			return # Ya existe, no hacer nada
			
	# Solo el fragmento visual, sin numeración
	var fragment = {
		"image": image_path,
		"name": fragment_name,
		"timestamp": Time.get_ticks_msec()
	}
	journal_data.fragments.append(fragment)
	save_data()
	refresh_fragments()
	
	# Verificar si desbloquea "misiones"
	check_fragment_milestones()

func add_signal(text: String, quest_id: String = ""):
	# Texto críptico sin contexto, con efecto de glitch
	var glitched_text = apply_glitch(text)
	
	# === LOGIC SYNC: Actualizar estado Global SIEMPRE (incluso si la señal ya existe) ===
	if quest_id == "dragona_hint":
		Global.shadow_met_hint_given = true
		Global.current_quest_stage = Global.QuestStage.SHADOW_MET
		print("Estado Global: SHADOW_MET y Hint Given (via journal sync)")
		
	if quest_id == "shadow_warning":
		Global.current_quest_stage = Global.QuestStage.SHADOW_MET
		Global.shadow_met_hint_given = true # CRITICAL FIX: Dragona necesita esto
		print("Estado Global: SHADOW_MET + Hint (via journal sync)")

	# Verificar si esta señal ya fue recibida (para evitar spam idéntico si es quest)
	if quest_id != "":
		for sig in journal_data.signals:
			if sig.has("quest_id") and sig.quest_id == quest_id:
				return # Ya tenemos esta pista clave, salimos (pero el Global ya se actualizó arriba)
	
	journal_data.signals.append({
		"text": glitched_text,
		"timestamp": Time.get_ticks_msec(),
		"quest_id": quest_id
	})
	
	# === LOGIC SYNC: Actualizar estado Global según señales clave ===
	if quest_id == "dragona_hint":
		Global.shadow_met_hint_given = true
		Global.current_quest_stage = Global.QuestStage.SHADOW_MET
		print("Estado Global: SHADOW_MET y Hint Given (via journal)")
		
	if quest_id == "shadow_warning":
		Global.current_quest_stage = Global.QuestStage.SHADOW_MET
		print("Estado Global: SHADOW_MET (via journal)")
		
	save_data()
	refresh_signals()
	
	# Notificar al jugador
	if not visible:
		new_signal_available = true
		if signal_notification:
			signal_notification.visible = true
			# Parpadeo rápido para llamar atención
			var tween = create_tween()
			tween.tween_property(signal_notification, "modulate:a", 0.0, 0.2)
			tween.tween_property(signal_notification, "modulate:a", 1.0, 0.2)
			tween.set_loops(3)

func check_fragment_milestones():
	var count = journal_data.fragments.size()
	if count == 3:
		add_signal("patrón visual detectado... iniciando búsqueda", "milestone_3_frags")
	elif count == 5:
		add_signal("memoria visual insuficiente... buscar más datos", "milestone_5_frags")
	elif count == 8:
		add_signal("archivo casi completo... la sombra se agita", "milestone_8_frags")

func apply_glitch(text: String) -> String:
	# Aplicar glitch aleatorio al texto
	if randf() < 0.3:
		return text
	
	var glitched = text
	var glitch_chars = ["█", "▓", "▒", "░", "∆", "", "╳", "≈"]
	
	# Insertar caracteres de glitch aleatorios
	for i in range(randi() % 3 + 1):
		var pos = randi() % glitched.length()
		var glitch_char = glitch_chars[randi() % glitch_chars.size()]
		glitched = glitched.insert(pos, glitch_char)
	
	return glitched

func refresh_fragments():
	# Limpiar contenedor
	for child in fragments_container.get_children():
		child.queue_free()
	
	# Agregar fragmentos
	for fragment in journal_data.fragments:
		var fragment_label = Label.new()
		fragment_label.text = "— " + fragment.name + " —"
		fragment_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fragment_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 1))
		fragments_container.add_child(fragment_label)
		
		# Intentar cargar la imagen
		if fragment.image != "" and ResourceLoader.exists(fragment.image):
			var texture = load(fragment.image)
			if texture:
				var texture_rect = TextureRect.new()
				texture_rect.texture = texture
				texture_rect.custom_minimum_size = Vector2(200, 200)
				texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
				texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				fragments_container.add_child(texture_rect)

func refresh_signals():
	# Limpiar contenedor
	for child in signals_container.get_children():
		child.queue_free()
	
	# Agregar señales con estética glitch
	for sig in journal_data.signals:
		var signal_label = RichTextLabel.new()
		signal_label.bbcode_enabled = true
		signal_label.fit_content = true
		signal_label.scroll_active = false
		signal_label.custom_minimum_size = Vector2(0, 30) # Altura mínima para evitar cortes
		
		# Timestamp con glitch
		var time_ms = int(sig.timestamp)
		var time_str = str(time_ms % 10000)
		
		# Formateo mejorado del texto para destacar pistas
		var text_content = sig.text
		text_content = text_content.replace("brilla", "[color=#00ffff][b]BRILLA[/b][/color]")
		text_content = text_content.replace("sombra", "[color=#a020f0][b]SOMBRA[/b][/color]")
		text_content = text_content.replace("portal", "[color=#ff00ff][b][wave]PORTAL[/wave][/b][/color]")
		text_content = text_content.replace("hilo", "[color=#ff0000][b]HILO ROJO[/b][/color]")
		text_content = text_content.replace("error", "[i]error[/i]")
		
		signal_label.text = "[color=#00ff00][" + time_str + "][/color] " + text_content
		signal_label.add_theme_font_size_override("normal_font_size", 16)
		
		signals_container.add_child(signal_label)
		
		# Separador
		var separator = HSeparator.new()
		separator.modulate = Color(0.3, 0.3, 0.3, 0.5)
		signals_container.add_child(separator)

func save_data():
	# Disabled per user request
	pass

func load_data():
	# Disabled per user request
	pass
