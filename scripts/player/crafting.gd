extends Node

# Recipe definitions
var recipes = {
	"FURNACE": {
		"Resources": {
			"STONE": 3,
		},
		"output_category": "Machines",
		"craft_time": 2.0
	},
	"FARM": {
		"Resources": {
			"WOOD": 5,
			"STONE": 2
		},
		"output_category": "Machines",
		"craft_time": 3.0
	},
	"HIVE": {
		"Resources": {
			"IRON_INGOT": 5,
			"STONE": 8,
			"WOOD": 10
		},
		"output_category": "Machines",
		"craft_time": 5.0
	},
	"DRILL": {
		"Resources": {
			"IRON_INGOT": 3,
			"STONE": 5
		},
		"output_category": "Machines",
		"craft_time": 3.0
	},
	"STORAGE_CRATE": {
		"Resources": {
			"WOOD": 10,
			"STONE": 5
		},
		"output_category": "Machines",
		"craft_time": 2.0
	},
	"COGS": {
		"Resources": {
			"WOOD": 2
		},
		"output_category": "Resources",
		"craft_time": 1.0
	},
	"CIRCUITS": {
		"Resources": {
			"IRON": 1,
			"GOLD": 1
		},
		"output_category": "Resources",
		"craft_time": 2.0
	},
	"CRAFTER": {
		"Resources": {
			"IRON_INGOT": 4,
			"STONE": 6,
			"COGS": 2,
			"CIRCUITS": 1
		},
		"output_category": "Machines",
		"craft_time": 4.0
	},
	"LANDFILL": {
		"Resources": {
			"WOOD": 5,
			"REFINED_STONE": 3
		},
		"output_category": "Machines",
		"craft_time": 2.0
	},
	"WARRIOR_ANT": {
		"Resources": {
			"IRON_INGOT": 2,
			"WOOD": 5
		},
		"output_category": "Machines",
		"craft_time": 3.0
	},
}

# State tracking
var currently_crafting = {}

# Core functionality
func _process(delta):
	_update_craft_timers(delta)

func can_craft(recipe_name: String) -> bool:
	if currently_crafting.has(recipe_name):
		return false
		
	if not recipes.has(recipe_name):
		return false
		
	return _has_required_resources(recipe_name)

func craft_item(recipe_name: String) -> bool:
	if can_craft(recipe_name):
		var requirements = recipes[recipe_name]
		currently_crafting[recipe_name] = requirements.craft_time
		
		_consume_resources(recipe_name)
		
		await get_tree().create_timer(requirements.craft_time).timeout
		Inventory.add_item(recipes[recipe_name].output_category, recipe_name, 1)
		return true
	return false

# Helper functions
func _update_craft_timers(delta):
	for recipe in currently_crafting.keys():
		currently_crafting[recipe] -= delta
		if currently_crafting[recipe] <= 0:
			currently_crafting.erase(recipe)

func _has_required_resources(recipe_name: String) -> bool:
	var requirements = recipes[recipe_name]
	for category in requirements:
		if category == "output_category" or category == "craft_time":
			continue
		for resource in requirements[category]:
			if Inventory.get_item_amount(category, resource) < requirements[category][resource]:
				return false
	return true

func _consume_resources(recipe_name: String):
	var requirements = recipes[recipe_name]
	for category in requirements:
		if category == "output_category" or category == "craft_time":
			continue
		for resource in requirements[category]:
			Inventory.add_item(category, resource, -requirements[category][resource])

func get_craft_progress(recipe_name: String) -> float:
	if currently_crafting.has(recipe_name):
		return 1.0 - (currently_crafting[recipe_name] / recipes[recipe_name].craft_time)
	return 0.0
