extends Node2D

@export var building_name = "FARM"
@export var food_production_rate = 1.0  # Food per second

var is_producing = false

func _ready():
	add_to_group("farms")

func set_production_active(active: bool):
	if active and !is_producing:
		FoodNetwork.register_producer(self, food_production_rate)
		is_producing = true
	elif !active and is_producing:
		FoodNetwork.unregister_producer(self)
		is_producing = false

func _exit_tree():
	if is_producing:
		FoodNetwork.unregister_producer(self)