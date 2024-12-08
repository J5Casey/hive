extends CharacterBody2D

# Configuration
@export var speed := 400.0
@export var run_speed_multiplier := 2
@export var min_zoom := 0.5
@export var max_zoom := 3.0
@export var zoom_speed := 5
@export var health := 100

# State tracking
var hovering_resource = null
var is_harvesting: bool = false

# Node references
@onready var camera = $Camera2D
@onready var sprite = $AnimatedSprite2D
@onready var collision = $CollisionShape2D

func _ready():
	_setup_camera()
	_connect_signals()

func _physics_process(delta):
	handle_movement(delta)
	handle_interaction(delta)
	handle_zoom(delta)

# Setup functions
func _setup_camera():
	camera.zoom = Vector2(max_zoom, max_zoom)

func _connect_signals():
	SignalBus.player_hovering_resource.connect(_on_player_hovering_resource)
	SignalBus.player_stopped_hovering_resource.connect(_on_player_stopped_hovering_resource)

# Movement handlers
func handle_movement(delta: float):
	var input_vector = _get_input_vector()
	
	if input_vector != Vector2.ZERO:
		_apply_movement(input_vector)
		sprite.play()
		SignalBus.player_position_changed.emit(global_position)
	else:
		velocity = Vector2.ZERO
		sprite.stop()
	
	move_and_slide()

func _get_input_vector() -> Vector2:
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()

func _apply_movement(input_vector: Vector2):
	var current_speed = speed * (run_speed_multiplier if Input.is_action_pressed("run") else 1.0)
	velocity = input_vector * current_speed
	rotation = velocity.angle() + PI/2

# Interaction handlers
func handle_interaction(_delta: float):
	if not hovering_resource:
		_stop_harvesting()
		return
		
	if not hovering_resource.harvestable:
		_stop_harvesting()
		return
		
	if Input.is_action_pressed("interact"):
		_start_harvesting()
	else:
		_stop_harvesting()

func _start_harvesting():
	if not is_harvesting:
		hovering_resource.start_harvesting()
		is_harvesting = true

func _stop_harvesting():
	if is_harvesting:
		if hovering_resource:
			hovering_resource.cancel_harvesting()
		is_harvesting = false

# Camera handlers
func handle_zoom(delta: float):
	var zoom_direction = Input.get_action_strength("zoom_in") - Input.get_action_strength("zoom_out")
	if zoom_direction != 0:
		_update_camera_zoom(zoom_direction * delta)

func _update_camera_zoom(zoom_amount: float):
	var new_zoom = camera.zoom + Vector2(zoom_speed * zoom_amount, zoom_speed * zoom_amount)
	new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
	new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
	camera.zoom = new_zoom

# Combat handlers
func take_damage(amount: int):
	health -= amount
	SignalBus.health_changed.emit(health)
	
	if health <= 0:
		_handle_death()

func _handle_death():
	SignalBus.player_died.emit()
	_reset_player()
	_temporarily_disable_combat()

func _reset_player():
	health = 100
	SignalBus.health_changed.emit(health)
	position = Vector2.ZERO
	Inventory.reset_inventory()

func _temporarily_disable_combat():
	remove_from_group("huntable")
	collision.disabled = true
	
	var readd_timer = Timer.new()
	readd_timer.one_shot = true
	readd_timer.wait_time = 1.0
	add_child(readd_timer)
	readd_timer.timeout.connect(_on_readd_to_huntable)
	readd_timer.start()
	
	var collision_timer = Timer.new()
	collision_timer.one_shot = true
	collision_timer.wait_time = 0.1
	add_child(collision_timer)
	collision_timer.timeout.connect(_on_reenable_collision)
	collision_timer.start()

# Signal handlers
func _on_player_hovering_resource(resource):
	hovering_resource = resource

func _on_player_stopped_hovering_resource():
	_stop_harvesting()
	hovering_resource = null

func _on_readd_to_huntable():
	add_to_group("huntable")

func _on_reenable_collision():
	collision.disabled = false
