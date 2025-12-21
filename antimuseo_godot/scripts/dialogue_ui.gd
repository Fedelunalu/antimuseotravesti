extends Control

@onready var character_name_label: Label = $Panel/MarginContainer/VBoxContainer/CharacterNameLabel
@onready var dialogue_text_label: RichTextLabel = $Panel/MarginContainer/VBoxContainer/DialogueTextLabel
@onready var options_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/OptionsContainer

signal option_selected(speaker: Node, index: int)

var is_timed = false

func _ready():
	visible = false
	# Asegurar que el UI pueda recibir clicks para las opciones
	mouse_filter = Control.MOUSE_FILTER_PASS
	if has_node("Panel"):
		$Panel.mouse_filter = Control.MOUSE_FILTER_STOP
		$Panel.z_index = 1000  # Asegurar que esté encima
	
	# Configurar el label de diálogo
	if dialogue_text_label:
		dialogue_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		dialogue_text_label.scroll_active = false  # Disable scroll to show all text

func show_dialogue(character_name: String, text: String):
	character_name_label.text = character_name
	dialogue_text_label.text = text
	
	# Hide options when showing regular dialogue
	if options_container:
		options_container.hide()
	
	visible = true
	# Por defecto capturar mouse para lectura (E avanzar)
	# Only change mouse mode if it's not already captured
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func show_options(options: Array):
	if not options_container: return
	
	# Clear previous options
	for child in options_container.get_children():
		child.queue_free()
	
	if options.is_empty():
		options_container.hide()
		return

	# Show mouse for clicking options
	# Only change mouse mode if it's not already visible
	if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Create new option buttons
	for i in range(options.size()):
		var btn = Button.new()
		btn.text = options[i]
		btn.custom_minimum_size.y = 30  # Reduce button height to prevent overflow
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT  # Left align text for better readability
		btn.focus_mode = Control.FOCUS_NONE  # Remove focus outline
		btn.pressed.connect(_on_option_pressed.bind(i))
		options_container.add_child(btn)
	
	options_container.show()
	visible = true

func _on_option_pressed(index):
	emit_signal("option_selected", Global.current_speaker, index)
	hide_options()

var last_advance_time = 0.0
var advance_cooldown = 0.1 # seconds

func _input(event):
	# Handle E key to advance dialogue when no options are shown
	if event.is_action_pressed("interact") and visible and options_container and not options_container.visible and not is_timed:
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - last_advance_time < advance_cooldown:
			return
			
		last_advance_time = current_time
		
		# Consume the event so it doesn't propagate to other scripts (like player interaction)
		get_viewport().set_input_as_handled()

		# Emit a signal to advance the dialogue with the current speaker
		emit_signal("option_selected", Global.current_speaker, 0)

func hide_dialogue():
	visible = false
	hide_options()
	# Only change mouse mode if it's not already captured
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func hide_options():
	if options_container:
		for child in options_container.get_children():
			child.queue_free()
		options_container.hide()