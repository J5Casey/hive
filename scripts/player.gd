extends CharacterBody2D

@export var speed := 400.0
@export var run_speed_multiplier := 2
@export var min_zoom := 0.2
@export var max_zoom := 1.0
@export var zoom_speed := 5

func _ready() -> void:
	$Camera2D.zoom = Vector2(max_zoom, max_zoom)

func _physics_process(delta: float) -> void:
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
		var rotation_angle = velocity.angle() + PI/2
		rotation = rotation_angle
	else:
		velocity = Vector2.ZERO
		$AnimatedSprite2D.stop()
	
	move_and_slide()
	handle_zoom(delta)

func handle_zoom(delta: float) -> void:
	var zoom_direction = Input.get_action_strength("zoom_in") - Input.get_action_strength("zoom_out")
	if zoom_direction != 0:
		var new_zoom = $Camera2D.zoom + Vector2(zoom_speed * zoom_direction * delta, zoom_speed * zoom_direction * delta)
		new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
		new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
		$Camera2D.zoom = new_zoom
