extends Area2D

@export var building_name = "HIVE"
@export var tile_radius = 20  # Number of tiles
var influence_radius = tile_radius * 64  # Converted to pixels
@export var base_food_consumption = 0.5  # Per second
var is_mouse_hovering = false

@onready var building_area = $CollisionShape2D
@onready var influence_area = $InfluenceArea/CollisionShape2D
@onready var influence_detector = $InfluenceArea

var farms_in_range = []

func _ready():
	add_to_group("hives")  
	# Set up the influence area shape
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = influence_radius
	influence_area.shape = circle_shape
	
	# Set ColorRect size based on influence radius
	var rect_size = Vector2(influence_radius * 2, influence_radius * 2)
	$InfluenceArea/RadiusVisual.size = rect_size
	$InfluenceArea/RadiusVisual.position = -rect_size/2
	
	# Connect the influence area signals
	influence_detector.area_entered.connect(_on_influence_area_entered)
	influence_detector.area_exited.connect(_on_influence_area_exited)
	
	FoodNetwork.register_consumer(self, base_food_consumption)
	
	# Manually check for existing farms within radius
	call_deferred("_detect_existing_farms")  # Ensure physics body is ready

func _detect_existing_farms():
	# Use the updated method for detecting farms
	var farms = get_tree().get_nodes_in_group("farms")
	for farm in farms:
		var distance = global_position.distance_to(farm.global_position)
		if distance <= influence_radius:
			if farm not in farms_in_range:
				farms_in_range.append(farm)
				farm.set_production_active(true)
func _exit_tree():
	# Clean up when the hive is removed
	FoodNetwork.unregister_consumer(self)
	for farm in farms_in_range:
		if is_instance_valid(farm):
			farm.set_production_active(false)
	farms_in_range.clear()

func _process(delta):
	FoodNetwork.consume_food(base_food_consumption * delta)

func _on_influence_area_entered(node: Node2D):
	# print("Node entered influence: ", node.name, " Groups: ", node.get_groups())
	if node.is_in_group("farms"):
		farms_in_range.append(node)
		node.set_production_active(true)
func _on_influence_area_exited(node: Node2D):
	if node.is_in_group("farms"):
		if node in farms_in_range:
			farms_in_range.erase(node)
			node.set_production_active(false)

func _on_mouse_entered():
	is_mouse_hovering = true
	$InfluenceArea/RadiusVisual.color = Color(0.5, 0.5, 1.0, 0.2)

func _on_mouse_exited():
	is_mouse_hovering = false
	$InfluenceArea/RadiusVisual.color = Color(0.5, 0.5, 1.0, 0.0)