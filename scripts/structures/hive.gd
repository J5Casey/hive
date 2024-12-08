extends Area2D

# Configuration
@export var building_name = "HIVE"
@export var tile_radius = 20
@export var base_food_consumption = 0.5
@export var is_ghost = false

# State tracking
var is_mouse_hovering = false
var influence_radius = tile_radius * 64
var farms_in_range = []
var warrior_ants_in_range = []

# Node references
@onready var building_area = $CollisionShape2D
@onready var influence_area = $InfluenceArea/CollisionShape2D
@onready var influence_detector = $InfluenceArea
@onready var radius_visual = $InfluenceArea/RadiusVisual

func _ready():
	if is_ghost:
		_setup_ghost_hive()
	else:
		_setup_active_hive()

# Setup functions
func _setup_ghost_hive():
	_setup_influence_area()
	_setup_visual_radius()

func _setup_active_hive():
	_setup_influence_area()
	_setup_visual_radius()
	_connect_signals()
	_register_with_food_network()
	call_deferred("_detect_existing_farms")

func _setup_influence_area():
	var rect_shape = RectangleShape2D.new()
	rect_shape.extents = Vector2(influence_radius, influence_radius)
	influence_area.shape = rect_shape

func _setup_visual_radius():
	var side_length = influence_radius * 2
	radius_visual.size = Vector2(side_length, side_length)
	radius_visual.position = -Vector2(influence_radius, influence_radius)

func _connect_signals():
	influence_detector.connect("area_entered", _on_influence_area_entered)
	influence_detector.connect("area_exited", _on_influence_area_exited)

func _register_with_food_network():
	FoodNetwork.register_consumer(self, base_food_consumption)

# Core functionality
func _detect_existing_farms():
	var farms = get_tree().get_nodes_in_group("farms")
	for farm in farms:
		var delta = farm.global_position - global_position
		if abs(delta.x) <= influence_radius and abs(delta.y) <= influence_radius:
			if farm not in farms_in_range:
				farms_in_range.append(farm)
				farm.set_production_active(true)

# Signal handlers
func _on_influence_area_entered(node: Node2D):
	if is_ghost:
		return

	if node.is_in_group("farms"):
		farms_in_range.append(node)
		node.set_production_active(true)
	elif node.is_in_group("warrior"):
		warrior_ants_in_range.append(node)
		node.set_production_active(true)
		node.set_hive_data(global_position, influence_radius)

func _on_influence_area_exited(node: Node2D):
	if is_ghost:
		return

	if node.is_in_group("farms"):
		if node in farms_in_range:
			farms_in_range.erase(node)
			node.set_production_active(false)
	elif node.is_in_group("warrior"):
		if node in warrior_ants_in_range:
			warrior_ants_in_range.erase(node)
			node.set_production_active(false)
			node.set_hive_data(null, 0)

func _on_mouse_entered():
	is_mouse_hovering = true
	radius_visual.color = Color(0.5, 0.5, 1.0, 0.2)

func _on_mouse_exited():
	is_mouse_hovering = false
	radius_visual.color = Color(0.5, 0.5, 1.0, 0.0)

func _exit_tree():
	if is_ghost:
		return
	
	FoodNetwork.unregister_consumer(self)
	for farm in farms_in_range:
		if is_instance_valid(farm):
			farm.set_production_active(false)
	farms_in_range.clear()
