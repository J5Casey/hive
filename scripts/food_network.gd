extends Node

var total_food: float = 0.0
var producers = {}  # Dictionary to track all producing buildings
var consumers = {}  # Dictionary to track all consuming buildings
var production_rate: float = 0.0
var consumption_rate: float = 0.0

signal food_updated(amount)

func register_producer(node: Node, rate: float):
	producers[node] = rate
	recalculate_rates()

func unregister_producer(node: Node):
	producers.erase(node)
	recalculate_rates()

func register_consumer(node: Node, rate: float):
	consumers[node] = rate
	recalculate_rates()

func unregister_consumer(node: Node):
	consumers.erase(node)
	recalculate_rates()

func recalculate_rates():
	production_rate = producers.values().reduce(func(accum, number): return accum + number, 0)
	consumption_rate = consumers.values().reduce(func(accum, number): return accum + number, 0)

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

func get_production_rate() -> float:
	return production_rate

func get_consumption_rate() -> float:
	return consumption_rate


func _process(delta):
	# Add food from production
	total_food += production_rate * delta
	# Remove food from consumption, but don't go below 0
	total_food = max(0, total_food - consumption_rate * delta)
