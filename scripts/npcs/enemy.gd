extends CharacterBody2D

# Configuration
@export var speed := 200.0
@export var detection_radius := 400.0
@export var attack_damage := 10
@export var attack_cooldown := 1.0
@export var max_health := 50

# State tracking
var health := max_health
var target = null
var can_attack := true
var entities_in_range = []

# Wander behavior
var wander_target = null
var wander_timer = 0.0
var wander_interval = 3.0

func _ready():
	_setup_detection()
	SignalBus.connect("player_died", _on_player_died)

func _physics_process(delta):
	if target and is_instance_valid(target):
		_handle_combat_movement()
	else:
		_handle_wander_movement(delta)

# Setup functions
func _setup_detection():
	$DetectionArea/CollisionShape2D.shape.radius = detection_radius
	$AttackTimer.wait_time = attack_cooldown

# Movement handlers
func _handle_combat_movement():
	var direction = global_position.direction_to(target.global_position)
	velocity = direction * speed
	move_and_slide()
	
	if can_attack and entities_in_range.size() > 0:
		attack(entities_in_range[0])

func _handle_wander_movement(delta):
	wander_timer += delta
	if _should_update_wander_target():
		_set_new_wander_target()
		
	if wander_target:
		_move_to_wander_target()
	else:
		_stop_movement()

# Wander helpers
func _should_update_wander_target() -> bool:
	return wander_timer >= wander_interval

func _set_new_wander_target():
	wander_timer = 0
	if randf() < 0.7:
		var angle = randf() * TAU
		var distance = randf_range(50, 200)
		wander_target = global_position + Vector2(cos(angle), sin(angle)) * distance
	else:
		wander_target = null

func _move_to_wander_target():
	var direction = global_position.direction_to(wander_target)
	velocity = direction * (speed * 0.5)
	move_and_slide()
	
	if global_position.distance_to(wander_target) < 10:
		wander_target = null

func _stop_movement():
	velocity = Vector2.ZERO
	move_and_slide()

# Combat functions
func attack(target_node):
	if target_node.has_method("take_damage"):
		target_node.take_damage(attack_damage)
	can_attack = false
	$AttackTimer.start()

func take_damage(amount):
	health -= amount
	if health <= 0:
		die()

func die():
	queue_free()

# Signal handlers
func _on_detection_area_body_entered(body):
	if body.is_in_group("huntable") and target == null:
		target = body

func _on_detection_area_body_exited(body):
	if body == target:
		target = null

func _on_attack_area_body_entered(body):
	if body.is_in_group("huntable"):
		entities_in_range.append(body)

func _on_attack_area_body_exited(body):
	entities_in_range.erase(body)

func _on_attack_timer_timeout():
	can_attack = true

func _on_player_died():
	if target and target.is_in_group("player"):
		target = null
