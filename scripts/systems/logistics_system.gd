extends Node2D

# Configuration
var trail_scene = preload("res://scenes/logistics/trail.tscn")
var custom_cursor = preload("res://assets/sprites/cursors/trail/trail_cursor.png")

# State tracking
var active_trails = []
var is_trail_mode = false
var is_placing_trail = false
var current_ghost_trail: Line2D = null
var start_building: Node = null
var hovered_building: Node = null
var trail_mode_label: Label

func _ready():
	_connect_signals()
	setup_trail_mode_ui()

func _process(delta):
	if is_trail_mode:
		_handle_trail_mode()

# Setup Functions
func _connect_signals():
	SignalBus.connect("inventory_opened", exit_trail_mode)
	SignalBus.connect("destroy_mode_entered", exit_trail_mode)

func setup_trail_mode_ui():
	trail_mode_label = Label.new()
	trail_mode_label.text = "TRAIL MODE"
	trail_mode_label.modulate = Color(0.2, 0.8, 0.2)
	trail_mode_label.visible = false
	add_child(trail_mode_label)

# Trail Mode Management
func _handle_trail_mode():
	update_hovered_building()
	_update_trail_mode_ui()
	
	if is_placing_trail and start_building and current_ghost_trail:
		_update_ghost_trail()

func enter_trail_mode():
	SignalBus.emit_signal("trail_mode_entered")
	is_trail_mode = true
	is_placing_trail = false
	start_building = null
	Input.set_custom_mouse_cursor(custom_cursor)
	trail_mode_label.visible = true

func exit_trail_mode():
	is_trail_mode = false
	is_placing_trail = false
	start_building = null
	Input.set_custom_mouse_cursor(null)
	trail_mode_label.visible = false
	_cleanup_ghost_trail()

# Trail Operations
func spawn_ghost_trail():
	current_ghost_trail = Line2D.new()
	current_ghost_trail.width = 4.0
	add_child(current_ghost_trail)

func _update_ghost_trail():
	current_ghost_trail.clear_points()
	current_ghost_trail.add_point(start_building.global_position)
	current_ghost_trail.add_point(get_global_mouse_position())
	update_ghost_validity()

func complete_trail(end_building: Node):
	var new_trail = trail_scene.instantiate()
	add_child(new_trail)
	new_trail.set_endpoints(start_building.global_position, end_building.global_position)
	new_trail.set_buildings(start_building, end_building)
	active_trails.append(new_trail)
	exit_trail_mode()
	unhighlight_building(end_building) 

# Building Interaction
func update_hovered_building():
	var areas = get_tree().get_nodes_in_group("logistics")
	var mouse_pos = get_global_mouse_position()
	
	for area in areas:
		if _is_mouse_over_building(area, mouse_pos):
			_handle_building_hover(area)
			return
	
	_clear_building_hover()

func handle_trail_click():
	if !hovered_building:
		return
		
	if !start_building:
		start_building = hovered_building
		spawn_ghost_trail()
		is_placing_trail = true
	else:
		if validate_connection(hovered_building):
			complete_trail(hovered_building)

# Helper Functions
func _is_mouse_over_building(area: Node, mouse_pos: Vector2) -> bool:
	var collision = area.get_node_or_null("CollisionShape2D")
	if collision and collision.shape:
		var local_point = mouse_pos - area.global_position
		return abs(local_point.x) <= collision.shape.size.x/2 and abs(local_point.y) <= collision.shape.size.y/2
	return false

func _handle_building_hover(area: Node):
	if hovered_building != area:
		if hovered_building:
			unhighlight_building(hovered_building)
		hovered_building = area
		highlight_building(hovered_building)

func _clear_building_hover():
	if hovered_building:
		unhighlight_building(hovered_building)
		hovered_building = null

func _cleanup_ghost_trail():
	if current_ghost_trail:
		current_ghost_trail.queue_free()
		current_ghost_trail = null

func _update_trail_mode_ui():
	trail_mode_label.global_position = get_global_mouse_position() + Vector2(20, -20)

# Visual Feedback
func highlight_building(building: Node):
	if !is_placing_trail:
		building.modulate = Color(0, 1, 0, 1)
	else:
		building.modulate = Color(0, 1, 1, 1) if validate_connection(building) else Color(1, 0, 0, 1)

func unhighlight_building(building: Node):
	building.modulate = Color(1, 1, 1, 1)

# Validation
func validate_connection(end_building: Node) -> bool:
	if !start_building or end_building == start_building:
		return false
		
	return start_building.is_within_hive_radius and end_building.is_within_hive_radius

func update_ghost_validity():
	if current_ghost_trail:
		var is_valid = validate_trail_placement()
		current_ghost_trail.default_color = Color(0, 1, 0, 0.5) if is_valid else Color(1, 0, 0, 0.5)

func validate_trail_placement() -> bool:
	if !hovered_building:
		return false
		
	if !hovered_building.is_in_group("logistics"):
		return false
		
	if start_building.has_method("set_production_active"):
		if !start_building.is_within_hive_radius:
			return false

	if hovered_building.has_method("set_production_active"):
		if !hovered_building.is_within_hive_radius:
			return false
			
	return true

# Input Handling
func _input(_event):
	if Input.is_action_just_pressed("enter_trail_mode"):
		if !is_trail_mode:
			enter_trail_mode()
		else:
			exit_trail_mode()
	
	elif is_trail_mode:
		if Input.is_action_just_pressed("place_building"):
			handle_trail_click()
		elif Input.is_action_just_pressed("escape_build_mode"):
			exit_trail_mode()
