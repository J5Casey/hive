extends Node

var building_scenes = {
	"FURNACE": preload("res://scenes/structures/furnace.tscn"),
	"FARM": preload("res://scenes/structures/farm.tscn"),
	"HIVE": preload("res://scenes/structures/hive.tscn")
}

var categories = {
	"Resources": {
		"WOOD": 0,
		"COAL": 2,
		"STONE": 0,
		"IRON": 2,
		"GOLD": 0,
		"IRON_INGOT": 0
	},
	"Machines": {
		"FURNACE": 4,
		"FARM": 4,
		"HIVE": 1
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
