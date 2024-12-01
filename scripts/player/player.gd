extends CharacterBody2D

@export var speed := 400.0
@export var run_speed_multiplier := 2
@export var min_zoom := 0.5
@export var max_zoom := 3.0
@export var zoom_speed := 5
@export var health := 100

var hovering_resource = null  

func _ready() -> void:
	$Camera2D.zoom = Vector2(max_zoom, max_zoom)
	SignalBus.player_hovering_resource.connect(_on_player_hovering_resource)
	SignalBus.player_stopped_hovering_resource.connect(_on_player_stopped_hovering_resource)

func handle_movement(delta: float) -> void:
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	
	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
		var current_speed = speed
		if Input.is_action_pressed("run"):
			current_speed *= run_speed_multiplier
		velocity = input_vector * current_speed
		$AnimatedSprite2D.play()

		# Emit the player position changed signal
		SignalBus.player_position_changed.emit(global_position)
		
		# Rotate the player based on movement direction
		var rotation_angle = velocity.angle() + PI / 2
		rotation = rotation_angle
	else:
		velocity = Vector2.ZERO
		$AnimatedSprite2D.stop()
	
	move_and_slide()

func handle_interaction() -> void:
	if Input.is_action_just_pressed("interact") and hovering_resource != null and hovering_resource.harvestable:
		hovering_resource.collect_resource()

func _physics_process(delta: float) -> void:
	handle_movement(delta)
	handle_interaction()
	handle_zoom(delta)
	
func handle_zoom(delta: float) -> void:
	var zoom_direction = Input.get_action_strength("zoom_in") - Input.get_action_strength("zoom_out")
	if zoom_direction != 0:
		var new_zoom = $Camera2D.zoom + Vector2(zoom_speed * zoom_direction * delta, zoom_speed * zoom_direction * delta)
		new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
		new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
		$Camera2D.zoom = new_zoom

func _on_player_hovering_resource(resource):
	hovering_resource = resource  # Store the resource node

func _on_player_stopped_hovering_resource():
	hovering_resource = null

func take_damage(amount: int) -> void:
	health -= amount
	SignalBus.health_changed.emit(health)
	# print("ouch")
	if health <= 0:
		# Handle player death
		# print("ded")
		SignalBus.player_died.emit()
		health = 100  # Reset health
		SignalBus.health_changed.emit(health)
		position = Vector2.ZERO  # Reset to spawn
		Inventory.reset_inventory()  # Clear inventory

		# Temporarily remove from 'huntable' group
		remove_from_group("huntable")

		# Re-add after a short delay
		var readd_timer = Timer.new()
		readd_timer.one_shot = true
		readd_timer.wait_time = 1.0  # Adjust delay as needed
		add_child(readd_timer)
		readd_timer.timeout.connect(_on_readd_to_huntable)
		readd_timer.start()

		# Disable collision shapes temporarily
		$CollisionShape2D.disabled = true

		# Re-enable collisions after a short delay
		var collision_timer = Timer.new()
		collision_timer.one_shot = true
		collision_timer.wait_time = 0.1  # Adjust delay as needed
		add_child(collision_timer)
		collision_timer.timeout.connect(_on_reenable_collision)
		collision_timer.start()

func _on_readd_to_huntable():
	add_to_group("huntable")

func _on_reenable_collision():
	$CollisionShape2D.disabled = false
