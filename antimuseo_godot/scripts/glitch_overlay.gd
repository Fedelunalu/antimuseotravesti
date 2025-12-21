extends TextureRect

@export var glitch_intensity: float = 0.05  # Reduced from 0.1 to 0.05
@export var fade_speed: float = 5.0

var _noise_texture: NoiseTexture2D
var _noise: FastNoiseLite
var _active_tween: Tween  # Keep track of active tween

func _ready():
	_noise = FastNoiseLite.new()
	_noise.seed = randi()
	_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	_noise.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	_noise.cellular_return_type = FastNoiseLite.CellularReturnType.RETURN_CELL_VALUE
	_noise.frequency = 0.5

	_noise_texture = NoiseTexture2D.new()
	_noise_texture.noise = _noise
	_noise_texture.width = 512
	_noise_texture.height = 512
	_noise_texture.seamless = true

	texture = _noise_texture
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	
	# Initial state: invisible
	self_modulate = Color(1, 1, 1, 0)
	visible = false

func show_glitch():
	visible = true
	var tween = create_tween()
	_active_tween = tween  # Store reference to tween
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self, "self_modulate", Color(1, 1, 1, glitch_intensity), 0.2)
	tween.tween_property(_noise, "offset", Vector3(randf_range(-100, 100), randf_range(-100, 100), 0), 0.1)
	tween.set_loops()

func hide_glitch():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self, "self_modulate", Color(1, 1, 1, 0), 0.5)
	await tween.finished
	visible = false
	
	# Kill the active tween if it exists
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	_active_tween = null

func _process(delta):
	# Update noise offset for animated look
	if visible:
		_noise.offset += Vector3(delta * 10, delta * 10, 0)
		_noise_texture.noise = _noise # Reassign to update the texture
