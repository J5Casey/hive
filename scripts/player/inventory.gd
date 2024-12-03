extends Node

var building_scenes = {
	"FURNACE": preload("res://scenes/structures/furnace.tscn"),
	"FARM": preload("res://scenes/structures/farm.tscn"),
	"HIVE": preload("res://scenes/structures/hive.tscn"),
	"DRILL": preload("res://scenes/structures/drill.tscn"),
	"STORAGE_CRATE": preload("res://scenes/structures/storage_crate.tscn"),
	"CRAFTER": preload("res://scenes/structures/crafter.tscn"),
	"LANDFILL": preload("res://scenes/structures/landfill.tscn"),
	"WARRIOR_ANT": preload("res://scenes/npcs/warrior_ant.tscn"),  
}

var categories = {
	"Resources": {
		"WOOD": 0,
		"COAL": 2,
		"STONE": 0,
		"IRON": 2,
		"GOLD": 0,
		"IRON_INGOT": 0,
		"COGS": 0,
		"CIRCUITS": 0,
		"REFINED_STONE": 0,
	},
	"Machines": {
		"FURNACE": 20,
		"FARM": 20,
		"HIVE": 20,
		"DRILL": 20,
		"STORAGE_CRATE": 20,
		"CRAFTER": 20,
		"LANDFILL": 20,
		"WARRIOR_ANT": 20, 
	},	
}

func _ready():
	SignalBus.connect("resource_collected", _on_resource_collected)
	# Toggle below comment for cheaty items for quick debugging
	reset_inventory()

func add_item(category: String, item_name: String, amount: int):
	if categories.has(category) and categories[category].has(item_name):
		categories[category][item_name] += amount

func get_item_amount(category: String, item_name: String) -> int:
	if categories.has(category) and categories[category].has(item_name):
		return categories[category][item_name]
	return 0

func _on_resource_collected(resource_name, amount):
	add_item("Resources", resource_name, amount)

func reset_inventory():
	for category in categories:
		for item in categories[category]:
			categories[category][item] = 0
