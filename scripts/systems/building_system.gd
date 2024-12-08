extends Node2D

# Configuration
var grid_size: int = 64
const DESTROY_TIME: float = 0.25

# State tracking
var is_building_mode: bool = false
var is_destroy_mode: bool = false
var current_ghost: Node2D = null
var hovered_building: Node2D = null
var destroy_timer: float = 0
var building_scene_to_place: PackedScene = null

# Node References
var destroy_mode_label: Label

func _ready():
	_connect_signals()
	setup_destroy_mode_ui()

func _process(delta):
	_handle_ghost_updates()
	_handle_destroy_mode(delta)

# Setup Functions
func _connect_signals():
	SignalBus.connect("building_selected_from_inventory", _on_building_selected)
	SignalBus.connect("inventory_opened", exit_building_mode)
	SignalBus.connect("trail_mode_entered", exit_destroy_mode)

func setup_destroy_mode_ui():
	destroy_mode_label = Label.new()
	destroy_mode_label.text = "DESTROY MODE"
	destroy_mode_label.modulate = Color(1, 0, 0)
	destroy_mode_label.visible = false
	add_child(destroy_mode_label)

# Building Mode Management
func enter_building_mode(building_scene: PackedScene):
	is_building_mode = true
	exit_destroy_mode()
	building_scene_to_place = building_scene
	spawn_ghost(building_scene)

func exit_building_mode():
	is_building_mode = false
	if is_instance_valid(current_ghost):
		current_ghost.queue_free()
		current_ghost = null

# Ghost Management
func spawn_ghost(building_scene: PackedScene):
	current_ghost = building_scene.instantiate()
	current_ghost.modulate = Color(1, 1, 1, 0.5)
	
	if "is_ghost" in current_ghost:
		current_ghost.is_ghost = true
	
	add_child(current_ghost)

func _handle_ghost_updates():
	if is_instance_valid(current_ghost):
		current_ghost.global_position = snap_to_grid(get_global_mouse_position())
		update_ghost_validity()

# Destroy Mode Management
func enter_destroy_mode():
	if is_building_mode:
		exit_building_mode()
	is_destroy_mode = true
	SignalBus.emit_signal("destroy_mode_entered")

func exit_destroy_mode():							
	is_destroy_mode = false
	hovered_building = null
	destroy_timer = 0
	Input.set_custom_mouse_cursor(null)
	destroy_mode_label.visible = false 

func toggle_destroy_mode():
	if is_destroy_mode:
		exit_destroy_mode()
	else:
		enter_destroy_mode()

func _handle_destroy_mode(delta):
	if is_destroy_mode:
		_process_destroy_mode(delta)
		_update_destroy_mode_ui()

func _process_destroy_mode(delta):
	var potential_building = _get_building_under_mouse()
	_handle_building_hover(potential_building)
	_handle_building_destruction(delta)

func _handle_building_hover(potential_building: Node2D):
	if potential_building != null:
		if potential_building != hovered_building:
			if hovered_building and is_instance_valid(hovered_building):
				hovered_building.modulate = Color(1, 1, 1, 1)  # Reset previous building's color
			destroy_timer = 0
			hovered_building = potential_building
	else:
		if hovered_building and is_instance_valid(hovered_building):
			hovered_building.modulate = Color(1, 1, 1, 1)  # Reset color
		hovered_building = null
		destroy_timer = 0

func _handle_building_destruction(delta):
	if hovered_building and is_instance_valid(hovered_building) and Input.is_action_pressed("destroy_building"):
		destroy_timer += delta
		var progress = destroy_timer / DESTROY_TIME
		hovered_building.modulate = Color(1, 1 - progress, 1 - progress, 1)
		
		if destroy_timer >= DESTROY_TIME:
			destroy_building(hovered_building)
			destroy_timer = 0

# Helper Functions
func snap_to_grid(pos: Vector2) -> Vector2:
	var snapped = Vector2(
		round(pos.x / grid_size) * grid_size,
		round(pos.y / grid_size) * grid_size
	)
	
	if current_ghost and (current_ghost.building_name == "DRILL" or 
						 current_ghost.building_name == "LANDFILL"):
		snapped += Vector2(grid_size/2, grid_size/2)
	
	return snapped

func update_ghost_validity() -> bool:
	if not current_ghost:
		return false
		
	var is_valid = true
	var overlapping_areas = current_ghost.get_overlapping_areas()
	
	if current_ghost.building_name == "LANDFILL":
		is_valid = _check_landfill_validity(overlapping_areas)
	elif current_ghost.building_name == "DRILL":
		is_valid = _check_drill_validity(overlapping_areas)
	else:
		is_valid = _check_general_building_validity(overlapping_areas)
	
	is_valid = is_valid and _check_inventory_validity()
	current_ghost.modulate = Color(1, 1, 1, 0.5) if is_valid else Color(1, 0, 0, 0.5)
	
	return is_valid

func _check_landfill_validity(areas) -> bool:
	for area in areas:
		if area.is_in_group("puddles"):
			return true
	return false

func _check_drill_validity(areas) -> bool:
	for area in areas:
		if area.is_in_group("resources"):
			return true
	return false

func _check_general_building_validity(areas) -> bool:
	for area in areas:
		if area.is_in_group("player_areas") or area.is_in_group("resource_areas") or area.is_in_group("influence_areas"):
			continue
		return false
	return true

func _check_inventory_validity() -> bool:
	return Inventory.get_item_amount("Machines", current_ghost.building_name) > 0

func _get_building_under_mouse() -> Node2D:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = get_global_mouse_position()
	query.collide_with_areas = true
	
	var result = space_state.intersect_point(query)
	for res in result:
		if res.collider.is_in_group("destroyable"):
			return res.collider
	return null

# UI Updates
func _update_destroy_mode_ui():
	destroy_mode_label.visible = is_destroy_mode
	destroy_mode_label.global_position = get_global_mouse_position() + Vector2(20, -20)
	Input.set_custom_mouse_cursor(preload("res://assets/sprites/cursors/destroy/destroy_cursor.png"))

# Building Operations
func place_building():
	if not current_ghost or not update_ghost_validity():
		return

	var new_building = building_scene_to_place.instantiate()
	new_building.global_position = current_ghost.global_position
	new_building.modulate = Color(1, 1, 1, 1)
	add_child(new_building)

	var building_name = new_building.building_name
	Inventory.add_item("Machines", building_name, -1)
	SignalBus.emit_signal("building_placed", new_building)

	if Inventory.get_item_amount("Machines", building_name) <= 0:
		exit_building_mode()

func destroy_building(building: Node2D):
	var building_name = building.building_name
	Inventory.add_item("Machines", building_name, 1)
	building.queue_free()

# Signal Handlers
func _on_building_selected(building_scene: PackedScene):
	if is_instance_valid(current_ghost):
		current_ghost.queue_free()
	enter_building_mode(building_scene)

# Input Handling
func _input(event: InputEvent):
	if event.is_action_pressed("enter_destroy_mode"):
		toggle_destroy_mode()
		
	if is_building_mode:
		if event.is_action_pressed("escape_build_mode"):
			exit_building_mode()
		elif event.is_action_pressed("place_building"):
			place_building()
			
	if is_destroy_mode:
		if event.is_action_pressed("escape_build_mode"):
			exit_destroy_mode()
