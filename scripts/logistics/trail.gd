extends Line2D

# Configuration
var transfer_rate = 1.0 
var food_cost_multiplier = 0.05 / 64 

# State tracking
var start_building: Node = null
var end_building: Node = null
var is_active = false
var transfer_timer = 0.0
var food_consumption_rate = 0.0

# Node references
@onready var start_point = $StartPoint
@onready var end_point = $EndPoint
@onready var area = $Area2D
@onready var collision_shape = $Area2D/CollisionShape2D

func _ready():
	_setup_visual_properties()
	setup_collision()

func _process(delta):
	if is_active and start_building and end_building:
		_handle_transfer(delta)

# Setup functions
func _setup_visual_properties():
	width = 4.0
	default_color = Color(0.8, 0.5, 0.2, 0.8)

func setup_collision():
	var shape = CapsuleShape2D.new()
	var length = start_point.position.distance_to(end_point.position)
	shape.height = length
	shape.radius = 10.0
	
	collision_shape.shape = shape
	collision_shape.rotation = (end_point.position - start_point.position).angle()
	collision_shape.position = (start_point.position + end_point.position) / 2

# Core functionality
func set_buildings(start: Node, end: Node):
	start_building = start
	end_building = end
	start_building.tree_exiting.connect(queue_free)
	end_building.tree_exiting.connect(queue_free)
	
	is_active = true
	food_consumption_rate = get_food_consumption_rate()
	FoodNetwork.register_consumer(self, food_consumption_rate)

func set_endpoints(start_pos: Vector2, end_pos: Vector2):
	points[0] = start_pos
	points[1] = end_pos
	start_point.global_position = start_pos
	end_point.global_position = end_pos
	setup_collision()

func _handle_transfer(delta):
	transfer_timer += delta
	if transfer_timer >= 1.0 / transfer_rate:
		attempt_transfer()
		transfer_timer = 0.0

func attempt_transfer():
	var source_storage = start_building.output_storage if "output_storage" in start_building else start_building.storage
	var target_storage = end_building.input_storage if "input_storage" in end_building else end_building.storage
	
	for item in source_storage:
		if source_storage[item] >= 1:
			if !target_storage.has(item):
				target_storage[item] = 0
			
			source_storage[item] -= 1
			target_storage[item] += 1
			
			_update_storage_displays()
			break

func _update_storage_displays():
	if start_building.has_method("update_storage_display"):
		start_building.update_storage_display()
	if end_building.has_method("update_storage_display"):
		end_building.update_storage_display()

func get_food_consumption_rate() -> float:
	var distance = start_point.position.distance_to(end_point.position)
	return distance * food_cost_multiplier * transfer_rate
