extends Area2D

@export var building_name = "DRILL"
var storage = {}
var current_resource = null
var collection_rate = 1.0  # Resources per second
var is_within_hive_radius = false

@onready var amount_label = Label.new()

func _ready():
	add_to_group("destroyable")
	add_child(amount_label)
	amount_label.position = Vector2(32, -20)  
	amount_label.add_theme_font_size_override("font_size", 20)
	amount_label.text = "0"
	modulate = Color(1, 0.5, 0.5, 1)  # Start red-tinted


func check_for_resource():
	var areas = get_overlapping_areas()
	for area in areas:
		if area.is_in_group("resources"):
			current_resource = area
			var resource_name = area.resource_names[area.resource_type]
			storage[resource_name] = 0
			print("Drill found resource: ", resource_name)
			break

func _process(delta):
	if current_resource and is_instance_valid(current_resource) and is_within_hive_radius:
		var resource_name = current_resource.resource_names[current_resource.resource_type]
		storage[resource_name] += collection_rate * delta
		amount_label.text = "%s: %.1f" % [resource_name, storage[resource_name]]
	else:
		call_deferred("check_for_resource")

func set_production_active(active: bool):
	# print("Drill production set to: ", active)
	is_within_hive_radius = active
	modulate = Color(1, 1, 1, 1) if active else Color(1, 0.5, 0.5, 1)
