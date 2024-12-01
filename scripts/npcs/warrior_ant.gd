# scripts/npcs/warrior_ant.gd
extends Area2D

@export var building_name = "WARRIOR_ANT"
@export var speed := 150.0
@export var attack_damage := 15
@export var attack_cooldown := 1.0
@export var food_consumption_rate := 0.2  # Food per second
@export var is_ghost := false

var target = null
var can_attack := true
var entities_in_range = []
var hive_position = null
var hive_radius = 0.0
var is_within_hive_radius = false  # Tracks if the ant is within a hive's influence

var patrol_target = null
var patrol_change_interval = 2.0  # Change target every 2 seconds
var patrol_timer = 0.0

@onready var character_body = $CharacterBody2D
@onready var attack_timer = $AttackTimer
@onready var collision_shape = $CollisionShape2D
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea

func _ready():
	if is_ghost:
		# Disable collisions and interactions during placement
		collision_shape.disabled = true
		detection_area.set_monitorable(false)
		attack_area.set_monitorable(false)
		return  # Skip further initialization

	# Enable collisions and interactions
	collision_shape.disabled = false
	detection_area.set_monitorable(true)
	attack_area.set_monitorable(true)

	attack_timer.wait_time = attack_cooldown

	# Connect signals
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)
	attack_timer.timeout.connect(_on_attack_timer_timeout)

	modulate = Color(1, 0.5, 0.5, 1)  # Start with a red tint to indicate inactive

func _physics_process(delta):
	if is_ghost or not is_within_hive_radius:
		character_body.velocity = Vector2.ZERO
		return

	var direction = Vector2.ZERO
	
	if target and is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
	else:
		if hive_position and global_position.distance_to(hive_position) > hive_radius:
			direction = (hive_position - global_position).normalized()
		else:
			patrol_timer += delta
			if patrol_timer >= patrol_change_interval or patrol_target == null:
				patrol_timer = 0.0
				patrol_target = get_random_position_within_hive()
			if patrol_target:
				direction = (patrol_target - global_position).normalized()

	character_body.velocity = direction * speed
	character_body.move_and_slide()
	
func _process(delta):
	if is_ghost or not is_within_hive_radius:
		return  # No actions while in ghost mode or inactive

	# Consume food over time
	if FoodNetwork.consume_food(food_consumption_rate * delta):
		# Food successfully consumed
		pass
	else:
		# Not enough food, perhaps handle starvation logic here
		pass

func set_production_active(active: bool):
	is_within_hive_radius = active
	if active:
		# Register with FoodNetwork
		FoodNetwork.register_consumer(self, food_consumption_rate)
		modulate = Color(1, 1, 1, 1)  # Normal color to indicate active
	else:
		# Unregister from FoodNetwork
		FoodNetwork.unregister_consumer(self)
		modulate = Color(1, 0.5, 0.5, 1)  # Red tint to indicate inactive
		target = null
		character_body.velocity = Vector2.ZERO
		patrol_target = null  # Reset patrol target

func set_hive_data(position, radius: float):
	hive_position = position
	hive_radius = radius

func get_random_position_within_hive() -> Vector2:
	# Generate a random angle and distance within the hive's influence radius
	var angle = randf() * TAU  # Random angle between 0 and 2π
	var distance = randf_range(0, hive_radius)
	var offset = Vector2(cos(angle), sin(angle)) * distance
	return hive_position + offset

func _on_detection_area_body_entered(body):
	if not is_within_hive_radius:
		return
	if body.is_in_group("enemies"):
		target = body

func _on_detection_area_body_exited(body):
	if body == target:
		target = null

func _on_attack_area_body_entered(body):
	if not is_within_hive_radius:
		return
	if body.is_in_group("enemies"):
		entities_in_range.append(body)

func _on_attack_area_body_exited(body):
	if body in entities_in_range:
		entities_in_range.erase(body)

func attack(target_node):
	if target_node and is_instance_valid(target_node) and target_node.has_method("take_damage"):
		target_node.take_damage(attack_damage)
	can_attack = false
	attack_timer.start()

func _on_attack_timer_timeout():
	can_attack = true

func _exit_tree():
	if is_within_hive_radius:
		FoodNetwork.unregister_consumer(self)
