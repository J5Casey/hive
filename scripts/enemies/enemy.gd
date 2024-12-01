extends CharacterBody2D

@export var speed := 200.0
@export var detection_radius := 400.0
@export var attack_damage := 10
@export var attack_cooldown := 1.0

var target = null
var can_attack := true
var entities_in_range = []

func _ready():
	$DetectionArea/CollisionShape2D.shape.radius = detection_radius
	$AttackTimer.wait_time = attack_cooldown

	# Connect to 'player_died' signal via SignalBus
	SignalBus.connect("player_died", _on_player_died)

func _physics_process(_delta):
	if target and is_instance_valid(target):
		var direction = global_position.direction_to(target.global_position)
		velocity = direction * speed
		move_and_slide()

		# Attack logic
		if can_attack and entities_in_range.size() > 0:
			attack(entities_in_range[0])
	else:
		# No target, stop moving
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

func _on_player_died():
	if target and target.is_in_group("player"):
		target = null
