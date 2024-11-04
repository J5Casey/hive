extends Node

var recipes = {
	"FURNACE": {
		"Resources": {
			"STONE": 3,
		},
		"output_category": "Machines"
	},
	"TOOL": {
		"Resources": {
			"IRON": 2,
			"WOOD": 1
		},
		"output_category": "Tools"
	}
}

func can_craft(recipe_name: String) -> bool:
	if not recipes.has(recipe_name):
		return false
		
	var requirements = recipes[recipe_name]
	for category in requirements:
		if category == "output_category":
			continue
		for resource in requirements[category]:
			if Inventory.get_item_amount(category, resource) < requirements[category][resource]:
				return false
	return true

func craft_item(recipe_name: String) -> bool:
	if can_craft(recipe_name):
		var requirements = recipes[recipe_name]
		# Consume resources
		for category in requirements:
			if category == "output_category":
				continue
			for resource in requirements[category]:
				Inventory.add_item(category, resource, -requirements[category][resource])
		
		# Add crafted item to inventory
		Inventory.add_item(recipes[recipe_name].output_category, recipe_name, 1)
		return true
	return false
