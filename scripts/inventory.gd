extends Node

var resources = {
	"WOOD": 0,
	"COAL": 0,
	"STONE": 0,
	"IRON": 0,
	"GOLD": 0
}

func add_resource(type: String, amount: int):
	resources[type] += amount

func get_resource_amount(type: String) -> int:
	return resources[type]
