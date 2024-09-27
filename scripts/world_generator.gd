extends Node2D

@export var tile_size := 64
@export var view_distance := 20

const ResourceScene = preload("res://scenes/resource.tscn")

var player_position := Vector2.ZERO

func _ready() -> void:
	SignalBus.player_position_changed.connect(_on_player_position_changed)
	_on_player_position_changed(Vector2(0,0))

func _on_player_position_changed(position: Vector2) -> void:
	player_position = position
	var player_tile_position = player_position / tile_size
	var start_x = round(player_tile_position.x - view_distance)
	var end_x = round(player_tile_position.x + view_distance)
	var start_y = round(player_tile_position.y - view_distance)
	var end_y = round(player_tile_position.y + view_distance)

	# Load tiles and spawn resources within the view distance
	for x in range(start_x, end_x + 1):
		for y in range(start_y, end_y + 1):
			var tile_pos = Vector2i(x, y)
			if $TileLayer0.get_cell_source_id(tile_pos) == -1:  # Check if the tile is not loaded
				$TileLayer0.set_cell(tile_pos, 0, Vector2i(0,0))  # Load the tile
				maybe_spawn_resource(tile_pos)

func maybe_spawn_resource(tile_position: Vector2i) -> void:
	if randf() < 0.05: #chance to spawn
		var resource = ResourceScene.instantiate()
		var resource_types = resource.ResourceType.values()
		var random_type = resource_types[randi() % resource_types.size()]
		resource.set_resource_type(random_type)
		resource.position = $TileLayer0.map_to_local(tile_position) 
		$ResourceLayer.add_child(resource)
