extends Node2D

@export var tile_size := 64
@export var view_distance := 20

var puddle_positions = {}  # Dictionary to keep track of puddle positions
var noise = FastNoiseLite.new()  # Initialize FastNoiseLite instance

const ResourceScene = preload("res://scenes/world/resource.tscn")
const PuddleScene = preload("res://scenes/world/puddle.tscn")

func _ready() -> void:
	SignalBus.player_position_changed.connect(_on_player_position_changed)
	
	# Configure FastNoiseLite parameters
	noise.seed = randi()  # Random seed for different patterns
	noise.noise_type = FastNoiseLite.TYPE_PERLIN  # Noise type
	noise.frequency = 0.01  # Controls the scale; smaller values create larger features
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM  # Set fractal type for detail
	noise.fractal_octaves = 2 # Number of noise layers; more octaves add detail
	noise.fractal_lacunarity = 2.0  # Frequency multiplier between octaves
	noise.fractal_gain = 0.7  # Amplitude of each octave; affects smoothness
	
	_on_player_position_changed(Vector2.ZERO)  # Generate initial tiles

func _on_player_position_changed(player_position: Vector2 = Vector2.ZERO) -> void:
	var player_tile_position = player_position / tile_size
	var start_x = round(player_tile_position.x - view_distance)
	var end_x = round(player_tile_position.x + view_distance)
	var start_y = round(player_tile_position.y - view_distance)
	var end_y = round(player_tile_position.y + view_distance)

	# Load tiles and determine terrain based view distance and on noise
	for x in range(start_x, end_x + 1):
		for y in range(start_y, end_y + 1):
			var tile_pos = Vector2i(x, y)
			if $TileLayer0.get_cell_source_id(tile_pos) == -1:  # Check if the tile is not loaded
				$TileLayer0.set_cell(tile_pos, 0, Vector2i(0, 0))  # Load the tile
				var noise_value = noise.get_noise_2d(float(x), float(y))
				# Check distance from spawn
				var distance_from_spawn = Vector2(tile_pos).length()
				if noise_value < -0.2 and distance_from_spawn > 20:  # No puddles within 20 tiles of spawn
					if not puddle_positions.has(tile_pos):
						spawn_puddle(tile_pos)
				else:
					maybe_spawn_resource(tile_pos)
func maybe_spawn_resource(tile_position: Vector2i) -> void:
	if is_puddle_at_position(tile_position):
		return  # Do not spawn resources on puddles
	if randf() < 0.005:  # Chance to spawn resource
		var resource = ResourceScene.instantiate()
		var resource_types = resource.ResourceType.values()
		var random_type = resource_types[randi() % resource_types.size()]
		resource.set_resource_type(random_type)
		resource.position = $TileLayer0.map_to_local(tile_position)
		$ResourceLayer.add_child(resource)

func spawn_puddle(tile_position: Vector2i) -> void:
	var puddle = PuddleScene.instantiate()
	puddle.position = $TileLayer0.map_to_local(tile_position)
	add_child(puddle)
	puddle_positions[tile_position] = puddle  # Keep track of puddle positions

func is_puddle_at_position(tile_position: Vector2i) -> bool:
	return puddle_positions.has(tile_position)
