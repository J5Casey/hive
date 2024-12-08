extends Area2D

# Configuration
@export var building_name = "DRILL"
@export var food_consumption_rate = 0.2
@export var collection_rate = 2.0

# State and Storage
var current_resource = null
var is_within_hive_radius = false
var output_storage = {}

# Node References
@onready var amount_label = Label.new()

func _ready():
	_setup_drill()

func _process(delta):
	if current_resource and is_instance_valid(current_resource) and is_within_hive_radius:
		_handle_resource_collection(delta)
	else:
		call_deferred("check_for_resource")

# Setup Functions
func _setup_drill():
	add_to_group("destroyable")
	add_child(amount_label)
	amount_label.position = Vector2(-5, -15)
	amount_label.add_theme_font_size_override("font_size", 16)
	modulate = Color(1, 0.5, 0.5, 1)

# Resource Management
func check_for_resource():
	var areas = get_overlapping_areas()
	for area in areas:
		if area.is_in_group("resources"):
			current_resource = area
			var resource_name = area.resource_names[area.resource_type]
			output_storage[resource_name] = 0
			break

func _handle_resource_collection(delta):
	if FoodNetwork.get_total_food() > 0:
		var resource_name = current_resource.resource_names[current_resource.resource_type]
		output_storage[resource_name] += collection_rate * delta
		amount_label.text = "%.0f" % [output_storage[resource_name]]

# Building State Management
func set_production_active(active: bool):
	is_within_hive_radius = active
	if active:
		FoodNetwork.register_consumer(self, food_consumption_rate)
		modulate = Color(1, 1, 1, 1)
	else:
		FoodNetwork.unregister_consumer(self)
		modulate = Color(1, 0.5, 0.5, 1)

func _exit_tree():
	if is_within_hive_radius:
		FoodNetwork.unregister_consumer(self)
