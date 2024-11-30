extends Node2D

var is_building_mode: bool = false
var is_destroy_mode: bool = false
var current_ghost: Node2D = null
var grid_size: int = 64
var hovered_building: Node2D = null
var destroy_timer: float = 0
const DESTROY_TIME: float = 0.25
var destroy_mode_label: Label
var building_scene_to_place: PackedScene = null

func _ready() -> void:
	SignalBus.connect("building_selected_from_inventory", _on_building_selected)
	SignalBus.connect("inventory_opened", exit_building_mode)
	SignalBus.connect("trail_mode_entered", exit_destroy_mode)
	setup_destroy_mode_ui()

func _process(delta: float) -> void:
	if current_ghost:
		var mouse_pos = get_global_mouse_position()
		current_ghost.global_position = snap_to_grid(mouse_pos)
		update_ghost_validity()
		
	if is_destroy_mode:
		process_destroy_mode(delta)
		destroy_mode_label.visible = true
		destroy_mode_label.global_position = get_global_mouse_position() + Vector2(20, -20)
		Input.set_custom_mouse_cursor(preload("res://assets/sprites/cursors/destroy/destroy_cursor.png"))
	else:
		destroy_mode_label.visible = false

func setup_destroy_mode_ui() -> void:
	destroy_mode_label = Label.new()
	destroy_mode_label.text = "DESTROY MODE"
	destroy_mode_label.modulate = Color(1, 0, 0)
	destroy_mode_label.visible = false
	add_child(destroy_mode_label)
	
func _on_building_selected(building_scene: PackedScene) -> void:
	if current_ghost:
		current_ghost.queue_free()
	enter_building_mode(building_scene)

func enter_building_mode(building_scene: PackedScene) -> void:
	is_building_mode = true
	exit_destroy_mode()
	building_scene_to_place = building_scene  # Store the scene to instantiate
	spawn_ghost(building_scene)

func exit_building_mode() -> void:
	is_building_mode = false
	if current_ghost:
		current_ghost.queue_free()
		current_ghost = null

func spawn_ghost(building_scene: PackedScene) -> void:
	current_ghost = building_scene.instantiate()
	current_ghost.modulate = Color(1, 1, 1, 0.5)
	
	if "is_ghost" in current_ghost:
		# Set a property to identify this as a ghost
		current_ghost.is_ghost = true
	
	add_child(current_ghost)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("enter_destroy_mode"):
		toggle_destroy_mode()
		
	if is_building_mode:
		if event.is_action_pressed("escape_build_mode"):
			exit_building_mode()
			return
			
		if event.is_action_pressed("place_building"):
			place_building()
			
	if is_destroy_mode:
		if event.is_action_pressed("escape_build_mode"):
			exit_destroy_mode()


func snap_to_grid(pos: Vector2) -> Vector2:
	return Vector2(
		round(pos.x / grid_size) * grid_size,
		round(pos.y / grid_size) * grid_size
	)

func update_ghost_validity() -> bool:
	if not current_ghost:
		return false
		
	var is_valid = true
	var overlapping_areas = current_ghost.get_overlapping_areas()
	
	# Special case for drill - must be on resource
	if current_ghost.building_name == "DRILL":
		is_valid = false  # Start false, only true if resource found
		for area in overlapping_areas:
			if area.is_in_group("resources"):
				is_valid = true
				break
	else:
		# Normal building validation
		for area in overlapping_areas:
			if area.is_in_group("player_areas") or area.is_in_group("resource_areas") or area.is_in_group("influence_areas"):
				continue
			is_valid = false
			break
	
	# Check inventory using the building name
	var building_name = current_ghost.building_name
	if Inventory.get_item_amount("Machines", building_name) <= 0:
		is_valid = false
	
	# Update ghost color
	current_ghost.modulate = Color(1, 1, 1, 0.5) if is_valid else Color(1, 0, 0, 0.5)
	
	return is_valid	

func place_building() -> void:
	if not current_ghost or not update_ghost_validity():
		return

	# Instantiate a new building from the stored scene
	var new_building = building_scene_to_place.instantiate()
	new_building.global_position = current_ghost.global_position
	new_building.modulate = Color(1, 1, 1, 1)
	add_child(new_building)

	var building_name = new_building.building_name
	Inventory.add_item("Machines", building_name, -1)

	SignalBus.emit_signal("building_placed", new_building)

	# Check if we can continue building
	if Inventory.get_item_amount("Machines", building_name) <= 0:
		exit_building_mode()

func destroy_building(building: Node2D) -> void:
	var building_name = building.building_name
	Inventory.add_item("Machines", building_name, 1)
	building.queue_free()

func process_destroy_mode(delta: float) -> void:
	var space_state = get_world_2d().direct_space_state
	var mouse_pos = get_global_mouse_position()
	
	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	query.collide_with_areas = true
	
	var result = space_state.intersect_point(query)
	
	if result.size() > 0:
		var potential_building = result[0].collider
		if potential_building.is_in_group("destroyable"):
			if potential_building != hovered_building:
				if hovered_building and is_instance_valid(hovered_building):
					hovered_building.modulate = Color(1, 1, 1, 1)  # Reset previous building
				destroy_timer = 0
				hovered_building = potential_building
	else:
		if hovered_building and is_instance_valid(hovered_building):
			hovered_building.modulate = Color(1, 1, 1, 1)  # Reset color
		hovered_building = null
		destroy_timer = 0
		
	if hovered_building and is_instance_valid(hovered_building) and Input.is_action_pressed("destroy_building"):
		destroy_timer += delta
		var progress = destroy_timer / DESTROY_TIME
		hovered_building.modulate = Color(1, 1-progress, 1-progress, 1)
		
		if destroy_timer >= DESTROY_TIME:
			destroy_building(hovered_building)
			destroy_timer = 0

func enter_destroy_mode() -> void:
	if is_building_mode:
		exit_building_mode()
	is_destroy_mode = true
	SignalBus.emit_signal("destroy_mode_entered")

func exit_destroy_mode() -> void:
	is_destroy_mode = false
	hovered_building = null
	destroy_timer = 0
	Input.set_custom_mouse_cursor(null)

func toggle_destroy_mode() -> void:
	if is_destroy_mode:
		exit_destroy_mode()
	else:
		enter_destroy_mode()
