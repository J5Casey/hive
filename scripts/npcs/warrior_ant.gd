# scripts/npcs/warrior_ant.gd
extends Area2D

@export var building_name = "WARRIOR_ANT"
@export var speed := 250.0
@export var attack_damage := 15
@export var attack_cooldown := 1.0
@export var food_consumption_rate := 0.2  # Food per second
@export var is_ghost := false
@export var max_health := 100  # Maximum health
@export var health_regen_rate := 2.0  # Health regenerated per second

var health := max_health
var target = null
var can_attack := true
var entities_in_range = []
var hive_position = null
var hive_radius = 0.0
var is_within_hive_radius = false  # Tracks if the ant is within the hive's influence
var is_active = true  # Tracks if the ant is active due to food availability
var velocity = Vector2.ZERO

var patrol_target = null
var patrol_change_interval = 2.0  # Change target every 2 seconds
var patrol_timer = 0.0

@onready var attack_timer = $AttackTimer
@onready var collision_shape = $CollisionShape2D
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea

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

	modulate = Color(1, 1, 1, 1)  # Start with normal color indicating active

func _physics_process(delta):
	if is_ghost or not is_within_hive_radius or not is_active:
		velocity = Vector2.ZERO
		return

	var direction = Vector2.ZERO

	if target and is_instance_valid(target):
		# Only act on the target if it's within hive influence radius
		if hive_position and target.global_position.distance_to(hive_position) <= hive_radius:
			# Move towards the enemy target
			direction = (target.global_position - global_position).normalized()
		else:
			# Target is outside hive radius; do not move towards it
			pass
	else:
		if hive_position and global_position.distance_to(hive_position) > hive_radius:
			# Return to hive if ant is outside hive radius
			direction = (hive_position - global_position).normalized()
		else:
			# Patrol within hive radius
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
		#Start animation and turn when moving
		$AnimatedSprite2D.play()
		rotation = velocity.angle() + PI/2
	else:
		# Stop animation when not moving
		$AnimatedSprite2D.stop()

	# Handle attacking
	if can_attack and entities_in_range.size() > 0:
		var attack_target = entities_in_range[0]
		# Only attack if target is within hive radius
		if hive_position and attack_target.global_position.distance_to(hive_position) <= hive_radius:
			attack(attack_target)
		else:
			# Do not attack target outside hive radius
			pass

func _process(delta):
	if is_ghost or not is_within_hive_radius:
		return  # No actions while outside hive radius

	if is_active:
		# Check if there's enough food
		if FoodNetwork.get_total_food() >= food_consumption_rate * delta:
			# Proceed with normal actions
			pass
		else:
			# Not enough food, deactivate ant
			deactivate()
	else:
		# If inactive due to lack of food, check if food is available to reactivate
		if FoodNetwork.get_total_food() >= food_consumption_rate * delta:
			activate()

	# Health regeneration
	if health < max_health:
		health += health_regen_rate * delta
		health = min(health, max_health)  # Ensure health doesn't exceed max

func activate():
	if not is_active:
		is_active = true
		modulate = Color(1, 1, 1, 1)  # Normal color indicating active
		# Register as consumer
		FoodNetwork.register_consumer(self, food_consumption_rate)
		# Re-enable monitoring
		detection_area.monitoring = true
		attack_area.monitoring = true
		# Process overlapping bodies in detection area
		for body in detection_area.get_overlapping_bodies():
			_on_detection_area_body_entered(body)
		for body in attack_area.get_overlapping_bodies():
			_on_attack_area_body_entered(body)

func deactivate():
	if is_active:
		is_active = false
		modulate = Color(1, 0.5, 0.5, 1)  # Red tint indicating inactive
		# Unregister as consumer
		FoodNetwork.unregister_consumer(self)
		# Disable monitoring to save resources
		detection_area.monitoring = false
		attack_area.monitoring = false
		target = null
		velocity = Vector2.ZERO
		patrol_target = null

func set_production_active(active: bool):
	is_within_hive_radius = active
	if not is_within_hive_radius:
		# If ant leaves hive influence, deactivate
		deactivate()
	else:
		# If ant enters hive influence and food is available, attempt to activate
		if not is_active and FoodNetwork.get_total_food() >= 0:
			activate()

func set_hive_data(position, radius):
	hive_position = position
	hive_radius = radius

func get_random_position_within_hive() -> Vector2:
	var angle = randf() * TAU  # Random angle between 0 and 2π
	var distance = randf_range(0, hive_radius)
	var offset = Vector2(cos(angle), sin(angle)) * distance
	return hive_position + offset

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

func attack(target_node):
	if target_node and is_instance_valid(target_node) \
			and target_node.has_method("take_damage"):
		target_node.take_damage(attack_damage)
	can_attack = false
	attack_timer.start()

func _on_attack_timer_timeout():
	can_attack = true

func take_damage(amount):
	health -= amount
	if health <= 0:
		die()

func die():
	# Unregister from FoodNetwork if still active
	if is_active:
		FoodNetwork.unregister_consumer(self)
	queue_free()

func _exit_tree():
	# Ensure we unregister from FoodNetwork if the ant is removed
	if is_active:
		FoodNetwork.unregister_consumer(self)
