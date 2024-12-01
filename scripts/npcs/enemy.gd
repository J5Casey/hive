extends CharacterBody2D

@export var speed := 200.0
@export var detection_radius := 400.0
@export var attack_damage := 10
@export var attack_cooldown := 1.0
@export var max_health := 50  # Added maximum health for the enemy

var health := max_health  # Current health of the enemy
var target = null
var can_attack := true
var entities_in_range = []

var wander_target = null
var wander_timer = 0.0
var wander_interval = 3.0  

func _ready():
	$DetectionArea/CollisionShape2D.shape.radius = detection_radius
	$AttackTimer.wait_time = attack_cooldown

	SignalBus.connect("player_died", _on_player_died)

func _physics_process(delta):
	if target and is_instance_valid(target):
		var direction = global_position.direction_to(target.global_position)
		velocity = direction * speed
		move_and_slide()
		
		if can_attack and entities_in_range.size() > 0:
			attack(entities_in_range[0])
	else:
		# Wandering behavior
		wander_timer += delta
		if wander_timer >= wander_interval:
			wander_timer = 0
			# 70% chance to pick new wander target, 30% chance to stop
			if randf() < 0.7:
				var angle = randf() * TAU  
				var distance = randf_range(50, 200)  
				wander_target = global_position + Vector2(cos(angle), sin(angle)) * distance
			else:
				wander_target = null
				
		if wander_target:
			var direction = global_position.direction_to(wander_target)
			velocity = direction * (speed * 0.5)  # Move at half speed while wandering
			move_and_slide()
			
			# If close to wander target, clear it
			if global_position.distance_to(wander_target) < 10:
				wander_target = null
		else:
			velocity = Vector2.ZERO
			move_and_slide()

func _on_detection_area_body_entered(body):
	if body.is_in_group("huntable") and target == null:
		target = body
		#print("Enemy acquired target: ", body.name)

func _on_detection_area_body_exited(body):
	if body == target:
		target = null

func _on_attack_area_body_entered(body):
	if body.is_in_group("huntable"):
		entities_in_range.append(body)

func _on_attack_area_body_exited(body):
	entities_in_range.erase(body)

func attack(target_node):
	if target_node.has_method("take_damage"):
		target_node.take_damage(attack_damage)
	can_attack = false
	$AttackTimer.start()

func _on_attack_timer_timeout():
	can_attack = true

func take_damage(amount):
	health -= amount
	if health <= 0:
		die()

func die():
	queue_free()

func _on_player_died():
	if target and target.is_in_group("player"):
		target = null
