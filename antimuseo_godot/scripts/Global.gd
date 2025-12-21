extends Node

var dialogue_ui: Node
var journal: Node

# Variables de Quest y Progreso Narrative
enum QuestStage { NONE, SHADOW_MET, SEARCHING_ARTIFACT, ARTIFACT_FOUND, RIDDLE_ACTIVE, PORTAL_OPEN }
var current_quest_stage = QuestStage.NONE
var shadow_interaction_count = 0 
var has_yarn = false 
var shadow_met_hint_given = false 
var intro_completed = false
var shadow_spawned = false
var video_watched = false
var video_playing = false
var red_thread_world_position = Vector3.ZERO

var current_speaker: Node = null

# Función para mostrar diálogo centralizada
func show_dialogue(speaker: Node, character_name: String, text: String):
	current_speaker = speaker
	if dialogue_ui:
		dialogue_ui.show_dialogue(character_name, text)

# Función para mostrar opciones centralizada
func show_options(speaker: Node, options: Array):
	current_speaker = speaker
	if dialogue_ui:
		dialogue_ui.show_options(options)

# Función para ocultar el diálogo, solo si el que pide ocultar es el que está hablando
# O si speaker es null (cierre forzado)
func hide_dialogue(speaker: Node = null):
	if dialogue_ui and (speaker == null or speaker == current_speaker):
		dialogue_ui.hide_dialogue()
		if speaker == current_speaker:
			current_speaker = null

func hide_options(speaker: Node = null):
	if dialogue_ui and (speaker == null or speaker == current_speaker):
		dialogue_ui.hide_options()

func add_signal(text: String, quest_id: String = ""):
	if journal:
		journal.add_signal(text, quest_id)

func add_fragment(image_path: String, fragment_name: String):
	if journal:
		journal.add_fragment(image_path, fragment_name)