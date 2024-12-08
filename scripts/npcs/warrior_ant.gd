extends Area2D

# Configuration
@export var building_name = "WARRIOR_ANT"
@export var speed := 250.0
@export var attack_damage := 15
@export var attack_cooldown := 1.0
@export var food_consumption_rate := 0.2
@export var is_ghost := false
@export var max_health := 100
@export var health_regen_rate := 2.0

# State tracking
var health := max_health
var target = null
var can_attack := true
var entities_in_range = []
var hive_position = null
var hive_radius = 0.0
var is_within_hive_radius = false  
var is_active = true 
var velocity = Vector2.ZERO

# Patrol state
var patrol_target = null
var patrol_change_interval = 2.0 
var patrol_timer = 0.0

# Node references
@onready var attack_timer = $AttackTimer
@onready var collision_shape = $CollisionShape2D
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea

# Core Functions
func _ready():
	if is_ghost:
		collision_shape.disabled = true
		detection_area.monitorable = false
		detection_area.monitoring = false
		attack_area.monitorable = false
		attack_area.monitoring = false
		return  

	collision_shape.disabled = false
	detection_area.monitorable = true
	detection_area.monitoring = true
	attack_area.monitorable = true
	attack_area.monitoring = true

	attack_timer.wait_time = attack_cooldown

	modulate = Color(1, 1, 1, 1) 

func _physics_process(delta):
	if is_ghost or not is_within_hive_radius or not is_active:
		velocity = Vector2.ZERO
		return

	var direction = Vector2.ZERO

	if target and is_instance_valid(target):
		if hive_position and target.global_position.distance_to(hive_position) <= hive_radius:
			direction = (target.global_position - global_position).normalized()
		else:
			pass
	else:
		if hive_position and global_position.distance_to(hive_position) > hive_radius:
			direction = (hive_position - global_position).normalized()
		else:
			patrol_timer += delta
			if patrol_timer >= patrol_change_interval or patrol_target == null \
					or global_position.distance_to(patrol_target) < 5:
				patrol_timer = 0.0
				patrol_target = get_random_position_within_hive()
			direction = (patrol_target - global_position).normalized()

	if direction != Vector2.ZERO:
		velocity = direction * speed
		position += velocity * delta
	else:
		velocity = Vector2.ZERO

	if velocity != Vector2.ZERO:
		$AnimatedSprite2D.play()
		rotation = velocity.angle() + PI/2
	else:
		$AnimatedSprite2D.stop()

	if can_attack and entities_in_range.size() > 0:
		var attack_target = entities_in_range[0]
		if hive_position and attack_target.global_position.distance_to(hive_position) <= hive_radius:
			attack(attack_target)
		else:
			pass

func _process(delta):
	if is_ghost or not is_within_hive_radius:
		return  

	if is_active:
		if FoodNetwork.get_total_food() >= food_consumption_rate * delta:
			pass
		else:
			deactivate()
	else:
		if FoodNetwork.get_total_food() >= food_consumption_rate * delta:
			activate()

	if health < max_health:
		health += health_regen_rate * delta
		health = min(health, max_health)  

# Combat System
func attack(target_node):
	if target_node and is_instance_valid(target_node) \
			and target_node.has_method("take_damage"):
		target_node.take_damage(attack_damage)
	can_attack = false
	attack_timer.start()

func take_damage(amount):
	health -= amount
	if health <= 0:
		die()

func die():
	if is_active:
		FoodNetwork.unregister_consumer(self)
	queue_free()

# State Management
func activate():
	if not is_active:
		is_active = true
		modulate = Color(1, 1, 1, 1)
		FoodNetwork.register_consumer(self, food_consumption_rate)
		detection_area.monitoring = true
		attack_area.monitoring = true

		for body in detection_area.get_overlapping_bodies():
			_on_detection_area_body_entered(body)
		for body in attack_area.get_overlapping_bodies():
			_on_attack_area_body_entered(body)

func deactivate():
	if is_active:
		is_active = false
		modulate = Color(1, 0.5, 0.5, 1)
		FoodNetwork.unregister_consumer(self)
		detection_area.monitoring = false
		attack_area.monitoring = false
		target = null
		velocity = Vector2.ZERO
		patrol_target = null

func set_production_active(active: bool):
	is_within_hive_radius = active
	if not is_within_hive_radius:
		deactivate()
	else:
		if not is_active and FoodNetwork.get_total_food() >= 0:
			activate()

# Movement and Patrolling
func set_hive_data(position, radius):
	hive_position = position
	hive_radius = radius

func get_random_position_within_hive() -> Vector2:
	var angle = randf() * TAU  # Random angle between 0 and 2π
	var distance = randf_range(0, hive_radius)
	var offset = Vector2(cos(angle), sin(angle)) * distance
	return hive_position + offset

# Signal Handlers
func _on_detection_area_body_entered(body):
	if not is_active:
		return
	if body.is_in_group("enemies"):
		target = body

func _on_detection_area_body_exited(body):
	if body == target:
		target = null

func _on_attack_area_body_entered(body):
	if not is_active:
		return
	if body.is_in_group("enemies"):
		entities_in_range.append(body)

func _on_attack_area_body_exited(body):
	if body in entities_in_range:
		entities_in_range.erase(body)

func _on_attack_timer_timeout():
	can_attack = true

func _exit_tree():
	if is_active:
		FoodNetwork.unregister_consumer(self)
