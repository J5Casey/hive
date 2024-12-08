extends Node2D

# Configuration
@export var building_name = "FARM"
@export var food_production_rate = 1.0

# State tracking
var is_within_hive_radius = false
var is_producing = false

func _ready():
	add_to_group("farms")

# Building State Management
func set_production_active(active: bool):
	is_within_hive_radius = active
	if active and !is_producing:
		FoodNetwork.register_producer(self, food_production_rate)
		is_producing = true
	elif !active and is_producing:
		FoodNetwork.unregister_producer(self)
		is_producing = false

func _exit_tree():
	if is_producing:
		FoodNetwork.unregister_producer(self)
