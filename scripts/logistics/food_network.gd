extends Node

signal food_updated(amount)

# Resource tracking
var total_food: float = 0.0
var production_rate: float = 0.0
var consumption_rate: float = 0.0

# Network registries
var producers = {}
var consumers = {}

# Public interface
func register_producer(node: Node, rate: float):
	producers[node] = rate
	_recalculate_rates()

func unregister_producer(node: Node):
	producers.erase(node)
	_recalculate_rates()

func register_consumer(node: Node, rate: float):
	consumers[node] = rate
	_recalculate_rates()

func unregister_consumer(node: Node):
	consumers.erase(node)
	_recalculate_rates()

func get_total_food() -> float:
	return total_food

func get_production_rate() -> float:
	return production_rate

func get_consumption_rate() -> float:
	return consumption_rate

# Core update
func _process(delta):
	var net_change = (production_rate - consumption_rate) * delta
	if abs(net_change) > 0.001:
		total_food = max(0, total_food + net_change)

# Helper functions
func _recalculate_rates():
	production_rate = producers.values().reduce(func(accum, number): return accum + number, 0)
	consumption_rate = consumers.values().reduce(func(accum, number): return accum + number, 0)
