extends Line2D

var start_building: Node = null
var end_building: Node = null
var transfer_rate = 1.0 # items per second
var food_cost_multiplier = 0.1 / 64 # food per tile distance
var is_active = false
var transfer_timer = 0.0

@onready var start_point = $StartPoint
@onready var end_point = $EndPoint
@onready var area = $Area2D
@onready var collision_shape = $Area2D/CollisionShape2D


func setup_collision():
	var shape = CapsuleShape2D.new()
	var length = start_point.position.distance_to(end_point.position)
	shape.height = length
	shape.radius = 10.0
	collision_shape.shape = shape
	
	# Rotate collision shape to match line direction
	var angle = (end_point.position - start_point.position).angle()
	collision_shape.rotation = angle
	collision_shape.position = (start_point.position + end_point.position) / 2

func set_endpoints(start_pos: Vector2, end_pos: Vector2):
	points[0] = start_pos
	points[1] = end_pos
	start_point.global_position = start_pos
	end_point.global_position = end_pos
	setup_collision()

func _ready():
	print("Trail initialized")
	setup_collision()
	width = 4.0
	default_color = Color(0.8, 0.5, 0.2, 0.8)

func set_buildings(start: Node, end: Node):
	print("Setting buildings: ", start.name, " to ", end.name)
	start_building = start
	end_building = end
	start_building.tree_exiting.connect(queue_free)
	end_building.tree_exiting.connect(queue_free)
	is_active = true
	print("Trail activated")
	
func _process(delta):
	if is_active and start_building and end_building:
		var food_cost = get_food_cost() * delta
		print("Attempting to consume food: ", food_cost)
		if FoodNetwork.consume_food(food_cost):
			print("Food consumed, attempting transfer")
			transfer_timer += delta
			if transfer_timer >= 1.0 / transfer_rate:
				attempt_transfer()
				transfer_timer = 0.0
				
func attempt_transfer():
	var source_storage = start_building.output_storage if "output_storage" in start_building else start_building.storage
	var target_storage = end_building.input_storage if "input_storage" in end_building else end_building.storage	
	for item in source_storage:
		if source_storage[item] >= 1:  # Only proceed if we have at least 1 item
			if !target_storage.has(item):
				target_storage[item] = 0
			source_storage[item] -= 1  # Remove first
			target_storage[item] += 1  # Then add
			if start_building.has_method("update_storage_display"):
				start_building.update_storage_display()
			if end_building.has_method("update_storage_display"):
				end_building.update_storage_display()
			break			
func get_food_cost() -> float:
	var distance = start_point.position.distance_to(end_point.position)
	return distance * food_cost_multiplier * transfer_rate 
