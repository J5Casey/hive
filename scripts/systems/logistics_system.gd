extends Node2D
var active_trails = []
var is_trail_mode = false
var is_placing_trail = false
var current_ghost_trail: Line2D = null
var start_building: Node = null
var hovered_building: Node = null
var trail_scene = preload("res://scenes/logistics/trail.tscn")
var trail_mode_label: Label
var custom_cursor = preload("res://assets/sprites/cursors/trail/trail_cursor.png")

func _ready():
	SignalBus.connect("inventory_opened", exit_trail_mode)
	SignalBus.connect("destroy_mode_entered", exit_trail_mode)
	setup_trail_mode_ui()

func setup_trail_mode_ui():
	trail_mode_label = Label.new()
	trail_mode_label.text = "TRAIL MODE"
	trail_mode_label.modulate = Color(0.2, 0.8, 0.2)
	trail_mode_label.visible = false
	add_child(trail_mode_label)

func _input(_event):
	if Input.is_action_just_pressed("enter_trail_mode"):
		#print("Trail mode toggled")
		if !is_trail_mode:
			enter_trail_mode()
		else:
			exit_trail_mode()
	
	elif is_trail_mode:
		if Input.is_action_just_pressed("place_building"):
			#print("Place building pressed in trail mode")
			handle_trail_click()
		elif Input.is_action_just_pressed("escape_build_mode"):
			exit_trail_mode()

func _process(delta):
	if !is_trail_mode:
		return
		
	update_hovered_building()
	trail_mode_label.global_position = get_global_mouse_position() + Vector2(20, -20)
	
	if is_placing_trail and start_building and current_ghost_trail:
		current_ghost_trail.clear_points()
		current_ghost_trail.add_point(start_building.global_position)
		current_ghost_trail.add_point(get_global_mouse_position())
		update_ghost_validity()

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
	if current_ghost_trail:
		current_ghost_trail.queue_free()
		current_ghost_trail = null
	if hovered_building:
		unhighlight_building(hovered_building)
		hovered_building = null

func update_hovered_building():
	var areas = get_tree().get_nodes_in_group("logistics")
	var mouse_pos = get_global_mouse_position()
	
	for area in areas:
		var collision = area.get_node_or_null("CollisionShape2D")
		if collision and collision.shape:
			var shape = collision.shape
			var local_point = mouse_pos - area.global_position
			if abs(local_point.x) <= shape.size.x/2 and abs(local_point.y) <= shape.size.y/2:
				if hovered_building != area:
					if hovered_building:
						unhighlight_building(hovered_building)
					hovered_building = area
					highlight_building(hovered_building)
				return
	
	if hovered_building:
		unhighlight_building(hovered_building)
		hovered_building = null
		
func highlight_building(building: Node):
	if !is_placing_trail:
		building.modulate = Color(0, 1, 0, 1)
	else:
		building.modulate = Color(0, 1, 1, 1) if validate_connection(building) else Color(1, 0, 0, 1)

func unhighlight_building(building: Node):
	building.modulate = Color(1, 1, 1, 1)

func handle_trail_click():
	#print("Trail click handled")
	if !hovered_building:
		#print("No hovered building")
		return
		
	if !start_building:
		#print("Setting start building: ", hovered_building.name)
		start_building = hovered_building
		spawn_ghost_trail()
		is_placing_trail = true
	else:
		#print("Attempting to complete trail")
		if validate_connection(hovered_building):
			#print("Connection validated")
			complete_trail(hovered_building)


func validate_connection(end_building: Node) -> bool:
	if !start_building or end_building == start_building:
		return false
		
	if !start_building.is_within_hive_radius:
		return false
	if !end_building.is_within_hive_radius:
		return false
	
	return true

func spawn_ghost_trail():
	current_ghost_trail = Line2D.new()
	current_ghost_trail.width = 4.0
	add_child(current_ghost_trail)

func complete_trail(end_building: Node):
	var new_trail = trail_scene.instantiate()
	add_child(new_trail)
	new_trail.set_endpoints(start_building.global_position, end_building.global_position)
	new_trail.set_buildings(start_building, end_building)
	active_trails.append(new_trail)
	exit_trail_mode()


func update_ghost_validity():
	if current_ghost_trail:
		var is_valid = validate_trail_placement()
		current_ghost_trail.default_color = Color(0, 1, 0, 0.5) if is_valid else Color(1, 0, 0, 0.5)

func validate_trail_placement():
	if !hovered_building:
		return false
		
	if !hovered_building.is_in_group("logistics"):
		return false
		
	# Check if both buildings are in hive radius
	if start_building.has_method("set_production_active"):
		if !start_building.is_within_hive_radius:
			return false

	if hovered_building.has_method("set_production_active"):
		if !hovered_building.is_within_hive_radius:
			return false
			
	return true
