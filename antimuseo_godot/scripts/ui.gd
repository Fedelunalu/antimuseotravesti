extends CanvasLayer

@onready var instructions_label = $InstructionsLabel
@onready var status_label = $StatusLabel
@onready var player = null

func _ready():
	instructions_label.text = "mira\nmuévete\npregunta\n\nel resto...\ndescubre"
	instructions_label.visible = true
	status_label.visible = false
	status_label.text = ""
	
	# Encontrar el jugador
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _process(_delta):
	# Ocultar estado de vuelo para mantener misterio
	pass

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		instructions_label.visible = !instructions_label.visible
