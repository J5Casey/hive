extends Area2D

@export var building_name = "HIVE"
@export var tile_radius = 15  # Number of tiles
var influence_radius = tile_radius * 64  # Converted to pixels
@export var base_food_consumption = 0.5  # Per second
var is_mouse_hovering = false

@onready var building_area = $CollisionShape2D
@onready var influence_area = $InfluenceArea/CollisionShape2D
@onready var influence_detector = $InfluenceArea

var farms_in_range = []

func _ready():
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
	



func _process(delta):
	FoodNetwork.consume_food(base_food_consumption * delta)

func _on_influence_area_entered(node: Node2D):
	if node.is_in_group("farms"):
		farms_in_range.append(node)
		node.is_within_hive_radius = true

func _on_influence_area_exited(node: Node2D):
	if node.is_in_group("farms"):
		farms_in_range.erase(node)
		node.is_within_hive_radius = false

func _on_mouse_entered():
	is_mouse_hovering = true
	print("Mouse entered")
	$InfluenceArea/RadiusVisual.color = Color(0.5, 1.0, 1.0, 0.2)

func _on_mouse_exited():
	is_mouse_hovering = false
	print("Mouse exited")
	$InfluenceArea/RadiusVisual.color = Color(0.5, 1.0, 1.0, 0.0)
