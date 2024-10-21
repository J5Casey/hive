extends Node

var resources = {
	"WOOD": 0,
	"COAL": 0,
	"STONE": 0,
	"IRON": 0,
	"GOLD": 0
}

func _ready():
	SignalBus.connect("resource_collected", _on_resource_collected)

func add_resource(type: String, amount: int):
	resources[type] += amount

func get_resource_amount(type: String) -> int:
	return resources[type]

func _on_resource_collected(resource_name, amount):
	add_resource(resource_name, amount)
	print("Collected ", amount, " ", resource_name, ". New total: ", get_resource_amount(resource_name))
