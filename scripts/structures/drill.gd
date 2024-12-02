extends Area2D

@export var building_name = "DRILL"
@export var food_consumption_rate = 0.2  # Food per second
@export var output_storage = {}  

var current_resource = null
var collection_rate = 2.0  # Resources per second
var is_within_hive_radius = false

@onready var amount_label = Label.new()

func _ready():
	add_to_group("destroyable")
	add_child(amount_label)
	amount_label.position = Vector2(-5, -15)  
	amount_label.add_theme_font_size_override("font_size", 16)
	modulate = Color(1, 0.5, 0.5, 1)  # Start red-tinted

func check_for_resource():
	var areas = get_overlapping_areas()
	for area in areas:
		if area.is_in_group("resources"):
			current_resource = area
			var resource_name = area.resource_names[area.resource_type]
			output_storage[resource_name] = 0
			#print("Drill found resource: ", resource_name)
			break

func _process(delta):
	if current_resource and is_instance_valid(current_resource) and is_within_hive_radius:
		if FoodNetwork.get_total_food() > 0:  # Only collect if we have food
			var resource_name = current_resource.resource_names[current_resource.resource_type]
			output_storage[resource_name] += collection_rate * delta
			amount_label.text = "%.0f" % [output_storage[resource_name]]
	else:
		call_deferred("check_for_resource")

func set_production_active(active: bool):
	is_within_hive_radius = active
	if active:
		FoodNetwork.register_consumer(self, food_consumption_rate)
	else:
		FoodNetwork.unregister_consumer(self)
	modulate = Color(1, 1, 1, 1) if active else Color(1, 0.5, 0.5, 1)

func _exit_tree():
	if is_within_hive_radius:
		FoodNetwork.unregister_consumer(self)
