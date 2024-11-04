extends Node

var categories = {
	"Resources": {
		"WOOD": 0,
		"COAL": 0,
		"STONE": 0,
		"IRON": 0,
		"GOLD": 0
	},
	"Machines": {
		"FURNACE": 0
	},
	"Tools": {
		"TOOL": 0
	}
}

func _ready():
	SignalBus.connect("resource_collected", _on_resource_collected)

func add_item(category: String, item_name: String, amount: int):
	if categories.has(category) and categories[category].has(item_name):
		categories[category][item_name] += amount

func get_item_amount(category: String, item_name: String) -> int:
	if categories.has(category) and categories[category].has(item_name):
		return categories[category][item_name]
	return 0

func _on_resource_collected(resource_name, amount):
	add_item("Resources", resource_name, amount)
