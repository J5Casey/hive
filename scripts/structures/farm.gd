extends Node2D

@export var building_name = "FARM"
@export var food_production_rate = 1.0  # Food per second

var is_within_hive_radius = false

func _ready():
	add_to_group("farms")

func _process(delta):
	if is_within_hive_radius:
		FoodNetwork.add_food(food_production_rate * delta)
