extends Area2D

@export var building_name = "HIVE"
@export var tile_radius = 20  # Number of tiles
@export var base_food_consumption = 0.5  # Per second
@export var is_ghost = false

@onready var building_area = $CollisionShape2D
@onready var influence_area = $InfluenceArea/CollisionShape2D
@onready var influence_detector = $InfluenceArea

var farms_in_range = []
var warrior_ants_in_range = []
var influence_radius = tile_radius * 64  
var is_mouse_hovering = false

func _ready():
	if is_ghost:
		# Set up the influence area shape for visualization only
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = influence_radius
		influence_area.shape = circle_shape

		# Set ColorRect size based on influence radius
		var rect_size = Vector2(influence_radius * 2, influence_radius * 2)
		$InfluenceArea/RadiusVisual.size = rect_size
		$InfluenceArea/RadiusVisual.position = -rect_size / 2

		# No need to connect signals or register with FoodNetwork
		return

	# Regular initialization for the actual hive
	# Set up the influence area shape
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = influence_radius
	influence_area.shape = circle_shape

	# Set ColorRect size based on influence radius
	$InfluenceArea/RadiusVisual.size = Vector2(influence_radius * 2, influence_radius * 2)
	$InfluenceArea/RadiusVisual.position = -Vector2(influence_radius, influence_radius)

	# Connect the influence area signals
	influence_detector.connect("area_entered", _on_influence_area_entered)
	influence_detector.connect("area_exited", _on_influence_area_exited)

	FoodNetwork.register_consumer(self, base_food_consumption)

	# Manually check for existing farms within radius
	call_deferred("_detect_existing_farms")

func _process(delta):
	if is_ghost:
		return  # Ghost hive doesn't need to process

	# Existing code for food consumption
	FoodNetwork.consume_food(base_food_consumption * delta)
	
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
	if self.has_meta("is_ghost") and is_ghost:
		# Skip cleanup for the ghost hive
		return
	
	# Clean up when the hive is removed
	FoodNetwork.unregister_consumer(self)
	for farm in farms_in_range:
		if is_instance_valid(farm):
			farm.set_production_active(false)
	farms_in_range.clear()

func _on_influence_area_entered(node: Node2D):
	if is_ghost:
		return  # Skip interactions for the ghost hive

	if node.is_in_group("farms"):
		farms_in_range.append(node)
		node.set_production_active(true)
	elif node.is_in_group("warrior"):
		#print("Warrior ant entered hive influence area:", node.name)
		warrior_ants_in_range.append(node)
		node.set_production_active(true)
		node.set_hive_data(global_position, influence_radius)

func _on_influence_area_exited(node: Node2D):
	if is_ghost:
		return  # Skip interactions for the ghost hive

	if node.is_in_group("farms"):
		if node in farms_in_range:
			farms_in_range.erase(node)
			node.set_production_active(false)
	elif node.is_in_group("warrior"):
		if node in warrior_ants_in_range:
			#print("Warrior ant exited hive influence area:", node.name)
			warrior_ants_in_range.erase(node)
			node.set_production_active(false)
			node.set_hive_data(null, 0)  

func _on_mouse_entered():
	is_mouse_hovering = true
	$InfluenceArea/RadiusVisual.color = Color(0.5, 0.5, 1.0, 0.2)

func _on_mouse_exited():
	is_mouse_hovering = false
	$InfluenceArea/RadiusVisual.color = Color(0.5, 0.5, 1.0, 0.0)
