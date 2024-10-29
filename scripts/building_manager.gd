extends Node2D

var building_to_place: PackedScene = null
var ghost_building: Node2D = null
var is_placing: bool = false

func start_placing(building_scene: PackedScene):
	building_to_place = building_scene
	is_placing = true
	# Instantiate a ghost building for visual feedback
	ghost_building = building_to_place.instantiate()
	ghost_building.modulate = Color(1, 1, 1, 0.5)  # Semi-transparent
	add_child(ghost_building)

func cancel_placing():
	if ghost_building:
		ghost_building.queue_free()
	building_to_place = null
	is_placing = false

func _process(delta):
	if is_placing:
		update_ghost_building_position()
		if Input.is_action_just_pressed("ui_accept"):
			place_building()
		elif Input.is_action_just_pressed("ui_cancel"):
			cancel_placing()

func update_ghost_building_position():
	var mouse_position = get_global_mouse_position()
	var grid_position = snap_to_grid(mouse_position)
	ghost_building.position = grid_position

func snap_to_grid(position: Vector2) -> Vector2:
	var grid_size = 64  # Tile size
	return Vector2(
		round(position.x / grid_size) * grid_size,
		round(position.y / grid_size) * grid_size
	)

func place_building():
	# Check if the placement is valid
	if not is_placement_valid(ghost_building.position):
		return  # Invalid placement

	# Instantiate the actual building
	var building = building_to_place.instantiate()
	building.position = ghost_building.position
	add_child(building)

	# Cleanup
	cancel_placing()

func is_placement_valid(position: Vector2) -> bool:
	# Define the area to check based on the building size
	var area = Rect2(position - Vector2(64, 64), Vector2(128, 128))
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_rect(area, [], 1, true, true)
	return result.size() == 0
