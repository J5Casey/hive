extends Area2D

@export var building_name = "CRAFTER"
@export var food_consumption_rate = 0.3  # Food per second

var recipes = {
	"FURNACE": {
		"inputs": {
			"STONE": 3
		},
		"outputs": {
			"FURNACE": 1
		},
		"craft_time": 2.0
	},
	"FARM": {
		"inputs": {
			"WOOD": 5,
			"STONE": 2
		},
		"outputs": {
			"FARM": 1
		},
		"craft_time": 3.0
	},
	"TOOL": {
		"inputs": {
			"IRON": 2,
			"WOOD": 1
		},
		"outputs": {
			"TOOL": 1
		},
		"craft_time": 1.0
	},
	"HIVE": {
		"inputs": {
			"IRON_INGOT": 5,
			"STONE": 8,
			"WOOD": 10
		},
		"outputs": {
			"HIVE": 1
		},
		"craft_time": 5.0
	},
	"DRILL": {
		"inputs": {
			"IRON_INGOT": 3,
			"STONE": 5
		},
		"outputs": {
			"DRILL": 1
		},
		"craft_time": 3.0
	},
	"STORAGE_CRATE": {
		"inputs": {
			"WOOD": 10,
			"STONE": 5
		},
		"outputs": {
			"STORAGE_CRATE": 1
		},
		"craft_time": 2.0
	},
	"COGS": {
	"inputs": {
		"WOOD": 2
	},
	"outputs": {
		"COGS": 1
	},
	"craft_time": 1.0
	},
	"CIRCUITS": {
		"inputs": {
			"IRON": 1,
			"GOLD": 1
		},
		"outputs": {
			"CIRCUITS": 1
		},
		"craft_time": 2.0
	}
}

var storage = {}
var current_recipe = null
var crafting_progress = 0.0
var is_crafting = false
var is_mouse_hovering = false
var is_within_hive_radius = false

static var current_open_crafter: Area2D = null

@onready var ui = $CanvasLayer/CrafterUI
@onready var recipe_container = $CanvasLayer/CrafterUI/Panel/Crafting/RecipeContainer
@onready var progress_bar = $CanvasLayer/CrafterUI/Panel/Crafting/ProgressBar
@onready var storage_container = $CanvasLayer/CrafterUI/Panel/Storage/StorageContainer
@onready var close_button = $CanvasLayer/CrafterUI/Panel/CloseButton

func _ready():
	ui.hide()
	close_button.pressed.connect(func(): ui.hide())
	modulate = Color(1, 0.5, 0.5, 1)  # Start red-tinted
	setup_recipe_buttons()  
	update_storage_display()

func setup_recipe_buttons():
	for recipe_name in recipes:
		var recipe_button = Button.new()
		recipe_button.text = recipe_name
		recipe_button.add_theme_font_size_override("font_size", 24)
		
		var tooltip = "Requires:\n"
		for item in recipes[recipe_name].inputs:
			tooltip += "- %s x%d\n" % [item, recipes[recipe_name].inputs[item]]
		tooltip += "\nProduces:\n"
		for item in recipes[recipe_name].outputs:
			tooltip += "- %s x%d\n" % [item, recipes[recipe_name].outputs[item]]
		recipe_button.tooltip_text = tooltip
		
		recipe_button.pressed.connect(
			func(): start_crafting(recipe_name)
		)
		recipe_container.add_child(recipe_button)

func update_recipe_buttons():
	for button in recipe_container.get_children():
		var recipe = recipes[button.text]
		var can_craft = true
		for item in recipe.inputs:
			if !storage.has(item) or storage[item] < recipe.inputs[item]:
				can_craft = false
				break
		button.disabled = !can_craft or !is_within_hive_radius

func update_storage_display():
	for child in storage_container.get_children():
		child.queue_free()
		
	for item in storage:
		if storage[item] > 0:
			var item_label = Label.new()
			item_label.text = "%s: %d" % [item, storage[item]]
			item_label.add_theme_font_size_override("font_size", 24)
			
			var transfer_button = Button.new()
			transfer_button.text = "Transfer"
			transfer_button.add_theme_font_size_override("font_size", 24)
			transfer_button.pressed.connect(func(): transfer_item(item))
			
			storage_container.add_child(item_label)
			storage_container.add_child(transfer_button)

func transfer_item(item):
	if storage[item] > 0:
		for category in Inventory.categories:
			if Inventory.categories[category].has(item):
				Inventory.add_item(category, item, 1)
				storage[item] -= 1
				update_storage_display()
				update_recipe_buttons()
				break

func complete_crafting():
	for item in current_recipe.outputs:
		if !storage.has(item):
			storage[item] = 0
		storage[item] += current_recipe.outputs[item]
	is_crafting = false
	current_recipe = null
	progress_bar.value = 0
	update_storage_display()
	update_recipe_buttons()

func start_crafting(recipe_name):
	if recipes.has(recipe_name) and is_within_hive_radius:
		current_recipe = recipes[recipe_name]
		if try_consume_ingredients():
			is_crafting = true
			crafting_progress = 0.0

func try_consume_ingredients():
	for item in current_recipe.inputs:
		if !storage.has(item) or storage[item] < current_recipe.inputs[item]:
			return false

	for item in current_recipe.inputs:
		storage[item] -= current_recipe.inputs[item]
	
	update_storage_display()
	update_recipe_buttons()
	return true

func _process(delta):
	if is_crafting and current_recipe and is_within_hive_radius:
		if FoodNetwork.get_total_food() > 0:
			crafting_progress += delta
			progress_bar.value = (crafting_progress / current_recipe.craft_time) * 100
			if crafting_progress >= current_recipe.craft_time:
				complete_crafting()

func set_production_active(active: bool):
	is_within_hive_radius = active
	if active:
		FoodNetwork.register_consumer(self, food_consumption_rate)
		modulate = Color(1, 1, 1, 1)
	else:
		FoodNetwork.unregister_consumer(self)
		modulate = Color(1, 0.5, 0.5, 1)

func _exit_tree():
	if is_within_hive_radius:
		FoodNetwork.unregister_consumer(self)

func interact():
	if current_open_crafter != null and current_open_crafter != self:
		current_open_crafter.ui.hide()
	
	current_open_crafter = self if !ui.visible else null
	ui.visible = !ui.visible
	
	if ui.visible:
		update_storage_display()
		update_recipe_buttons()

func _input(event):
	if event.is_action_pressed("interact"):
		if !ui.visible and is_mouse_hovering:
			interact()
		elif ui.visible:
			interact()

func _on_mouse_entered():
	is_mouse_hovering = true

func _on_mouse_exited():
	is_mouse_hovering = false
