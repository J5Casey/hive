extends Area2D

@export var building_name = "CRAFTER"
@export var food_consumption_rate = 0.3  # Food per second
@export var input_storage = {}
@export var output_storage = {}

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
	},
	"LANDFILL": {
		"inputs": {
			"WOOD": 5,
			"REFINED_STONE": 3
		},
		"outputs": {
			"LANDFILL": 1
		},
		"craft_time": 2.0
	},
	"WARRIOR_ANT": {
		"inputs": {
			"IRON_INGOT": 2,
			"WOOD": 5
		},
		"outputs": {
			"WARRIOR_ANT": 1
		},
		"craft_time": 3.0
	},
	"CRAFTER": {
	"inputs": {
		"IRON_INGOT": 4,
		"STONE": 6,
		"COGS": 2,
		"CIRCUITS": 1
	},
	"outputs": {
		"CRAFTER": 1
	},
	"craft_time": 4.0
	},
}

var active_recipe = null
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

func _process(delta):
	update_recipe_buttons()

	if active_recipe and is_within_hive_radius:
		if FoodNetwork.get_total_food() > 0:
			if !is_crafting and try_consume_ingredients():
				is_crafting = true
				crafting_progress = 0.0
		
			if is_crafting:
				crafting_progress += delta
				progress_bar.value = (crafting_progress / active_recipe.craft_time) * 100
				if crafting_progress >= active_recipe.craft_time:
					complete_crafting()


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
		button.disabled = !is_within_hive_radius

func update_storage_display():
	for child in storage_container.get_children():
		child.queue_free()
	
	# Display input storage
	var input_label = Label.new()
	input_label.text = "Input Storage:"
	input_label.add_theme_font_size_override("font_size", 24)
	storage_container.add_child(input_label)
	
	for item in input_storage:
		var item_container = HBoxContainer.new()
		
		var item_label = Label.new()
		item_label.text = "%s: %d" % [item, input_storage[item]]
		item_label.add_theme_font_size_override("font_size", 24)
		
		var transfer_button = Button.new()
		transfer_button.text = "Transfer From Inventory"
		transfer_button.add_theme_font_size_override("font_size", 24)
		transfer_button.pressed.connect(func(): transfer_from_inventory(item))
		
		item_container.add_child(item_label)
		item_container.add_child(transfer_button)
		storage_container.add_child(item_container)
	
	# Display output storage
	var output_label = Label.new()
	output_label.text = "Output Storage:"
	output_label.add_theme_font_size_override("font_size", 24)
	storage_container.add_child(output_label)
	
	for item in output_storage:
		if output_storage[item] > 0:
			var item_container = HBoxContainer.new()
			
			var item_label = Label.new()
			item_label.text = "%s: %d" % [item, output_storage[item]]
			item_label.add_theme_font_size_override("font_size", 24)
			
			var transfer_button = Button.new()
			transfer_button.text = "Transfer To Inventory"
			transfer_button.add_theme_font_size_override("font_size", 24)
			transfer_button.pressed.connect(func(): transfer_item(item))
			
			item_container.add_child(item_label)
			item_container.add_child(transfer_button)
			storage_container.add_child(item_container)

func transfer_item(item):
	if input_storage[item] > 0:
		for category in Inventory.categories:
			if Inventory.categories[category].has(item):
				Inventory.add_item(category, item, 1)
				input_storage[item] -= 1
				update_storage_display()
				update_recipe_buttons()
				break

func complete_crafting():
	for item in active_recipe.outputs:
		if !output_storage.has(item):
			output_storage[item] = 0
		output_storage[item] += active_recipe.outputs[item]
	is_crafting = false
	progress_bar.value = 0
	update_storage_display()
	update_recipe_buttons()

func start_crafting(recipe_name):
	active_recipe = recipes[recipe_name]

func try_consume_ingredients():
	for item in active_recipe.inputs:
		if !input_storage.has(item) or input_storage[item] < active_recipe.inputs[item]:
			return false

	for item in active_recipe.inputs:
		input_storage[item] -= active_recipe.inputs[item]
		update_storage_display()
		update_recipe_buttons()
		return true

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

func transfer_from_inventory(item):
	for category in Inventory.categories:
		if Inventory.categories[category].has(item):
			if Inventory.get_item_amount(category, item) > 0:
				if !input_storage.has(item):
					input_storage[item] = 0
				input_storage[item] += 1
				Inventory.add_item(category, item, -1)
				update_storage_display()
				update_recipe_buttons()
				break
