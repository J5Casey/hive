extends Node

var total_food: float = 0.0
var food_consumption_rate: float = 0.0

signal food_updated(amount)

func add_food(amount: float):
	total_food += amount
	emit_signal("food_updated", total_food)

func consume_food(amount: float) -> bool:
	if total_food >= amount:
		total_food -= amount
		emit_signal("food_updated", total_food)
		return true
	return false

func get_total_food() -> float:
	return total_food
