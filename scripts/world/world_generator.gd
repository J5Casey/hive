extends Node2D

# Configuration
@export var tile_size := 64
@export var view_distance := 20

# State tracking
var puddle_positions = {}

# Noise Configuration
var noise = FastNoiseLite.new()

# Preloaded Scenes
const ResourceScene = preload("res://scenes/world/resource.tscn")
const PuddleScene = preload("res://scenes/world/puddle.tscn")
const EnemyScene = preload("res://scenes/npcs/enemy.tscn")

func _ready():
	_connect_signals()
	_setup_noise()
	_on_player_position_changed(Vector2.ZERO)  # Generate initial tiles

func _connect_signals():
	SignalBus.player_position_changed.connect(_on_player_position_changed)
	SignalBus.connect("request_puddle_removal", _on_request_puddle_removal)

# Noise Setup - Controls world generation patterns
func _setup_noise():
	noise.seed = randi()  # Random seed ensures different patterns each game
	noise.noise_type = FastNoiseLite.TYPE_PERLIN  # Perlin noise gives smooth, natural-looking transitions
	noise.frequency = 0.03  # Lower values = larger features, higher values = more compressed features
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM  # FBM (Fractal Brownian Motion) adds natural-looking detail
	noise.fractal_octaves = 2  # Each octave adds a layer of detail, but costs performance
	noise.fractal_lacunarity = 2.0  # How much the frequency increases each octave
	noise.fractal_gain = 0.7  # How much each octave contributes to the final shape

# World Generation
func _on_player_position_changed(player_position: Vector2 = Vector2.ZERO):
	var player_tile_position = player_position / tile_size
	var start_x = round(player_tile_position.x - view_distance)
	var end_x = round(player_tile_position.x + view_distance)
	var start_y = round(player_tile_position.y - view_distance)
	var end_y = round(player_tile_position.y + view_distance)

	for x in range(start_x, end_x + 1):
		for y in range(start_y, end_y + 1):
			var tile_pos = Vector2i(x, y)
			if $TileLayer1.get_cell_source_id(tile_pos) == -1:
				_generate_tile(tile_pos)

func _generate_tile(tile_pos: Vector2i):
	# Place base tile
	$TileLayer1.set_cell(tile_pos, 0, Vector2i(0, 0))
	
	# Get noise value for this position
	var noise_value = noise.get_noise_2d(float(tile_pos.x), float(tile_pos.y))
	var distance_from_spawn = Vector2(tile_pos).length()
	
	# Generate features based on noise and distance
	if noise_value < -0.25 and distance_from_spawn > 20:  # Puddles
		if not puddle_positions.has(tile_pos):
			spawn_puddle(tile_pos)
	else:  # Resources
		maybe_spawn_resource(tile_pos)
	
	# Enemies spawn with low probability far from spawn
	if randf() < 0.001 and distance_from_spawn > 30:
		var spawn_position = $TileLayer1.map_to_local(tile_pos)
		if not is_puddle_at_position(tile_pos):
			spawn_enemy(spawn_position)

# Feature Spawning
func spawn_enemy(position: Vector2):
	var enemy = EnemyScene.instantiate()
	enemy.position = position
	$EnemyLayer.add_child(enemy)

func maybe_spawn_resource(tile_position: Vector2i):
	if is_puddle_at_position(tile_position):
		return
	
	if randf() < 0.005:  # 0.5% chance to spawn resource
		var resource = ResourceScene.instantiate()
		var resource_types = resource.ResourceType.values()
		var random_type = resource_types[randi() % resource_types.size()]
		resource.set_resource_type(random_type)
		resource.position = $TileLayer1.map_to_local(tile_position)
		$ResourceLayer.add_child(resource)

func spawn_puddle(tile_position: Vector2i):
	var puddle = PuddleScene.instantiate()
	puddle.position = $TileLayer1.map_to_local(tile_position)
	add_child(puddle)
	puddle_positions[tile_position] = puddle

# Puddle Management
func _on_request_puddle_removal(position: Vector2):
	var tile_position = $TileLayer1.local_to_map(position)
	remove_puddle_at_position(tile_position)

func remove_puddle_at_position(tile_position: Vector2i):
	if puddle_positions.has(tile_position):
		var puddle = puddle_positions[tile_position]
		if is_instance_valid(puddle):
			puddle.queue_free()
		puddle_positions.erase(tile_position)

func is_puddle_at_position(tile_position: Vector2i) -> bool:
	return puddle_positions.has(tile_position)
