extends Area2D

# Configuration and Recipes
@export var building_name = "CRAFTER"
@export var food_consumption_rate = 0.3

# Recipe definitions
var recipes = {
	"FURNACE": {
		"inputs": {"STONE": 3},
		"outputs": {"FURNACE": 1},
		"craft_time": 2.0
	},
	"FARM": {
		"inputs": {"WOOD": 5, "STONE": 2},
		"outputs": {"FARM": 1},
		"craft_time": 3.0
	},
	"HIVE": {
		"inputs": {"IRON_INGOT": 5, "STONE": 8, "WOOD": 10},
		"outputs": {"HIVE": 1},
		"craft_time": 5.0
	},
	"DRILL": {
		"inputs": {"IRON_INGOT": 3, "STONE": 5},
		"outputs": {"DRILL": 1},
		"craft_time": 3.0
	},
	"STORAGE_CRATE": {
		"inputs": {"WOOD": 10, "STONE": 5},
		"outputs": {"STORAGE_CRATE": 1},
		"craft_time": 2.0
	},
	"COGS": {
		"inputs": {"WOOD": 2},
		"outputs": {"COGS": 1},
		"craft_time": 1.0
	},
	"CIRCUITS": {
		"inputs": {"IRON": 1, "GOLD": 1},
		"outputs": {"CIRCUITS": 1},
		"craft_time": 2.0
	},
	"LANDFILL": {
		"inputs": {"WOOD": 5, "REFINED_STONE": 3},
		"outputs": {"LANDFILL": 1},
		"craft_time": 2.0
	},
	"WARRIOR_ANT": {
		"inputs": {"IRON_INGOT": 2, "WOOD": 5},
		"outputs": {"WARRIOR_ANT": 1},
		"craft_time": 3.0
	},
	"CRAFTER": {
		"inputs": {"IRON_INGOT": 4, "STONE": 6, "COGS": 2, "CIRCUITS": 1},
		"outputs": {"CRAFTER": 1},
		"craft_time": 4.0
	},
}


# State and Storage
var active_recipe = null
var crafting_progress = 0.0
var is_crafting = false
var is_mouse_hovering = false
var is_within_hive_radius = false
var input_storage = {}
var output_storage = {}
static var current_open_crafter: Area2D = null

# Node References
@onready var ui = $CanvasLayer/CrafterUI
@onready var recipe_container = $CanvasLayer/CrafterUI/Panel/Crafting/RecipeContainer
@onready var progress_bar = $CanvasLayer/CrafterUI/Panel/Crafting/ProgressBar
@onready var storage_container = $CanvasLayer/CrafterUI/Panel/Storage/StorageContainer
@onready var close_button = $CanvasLayer/CrafterUI/Panel/CloseButton

# Core Functions
func _ready():
	ui.hide()
	close_button.pressed.connect(func(): ui.hide())
	modulate = Color(1, 0.5, 0.5, 1)
	setup_recipe_buttons()
	update_storage_display()

func _process(delta):
	if active_recipe and is_within_hive_radius:
		_handle_crafting(delta)

func _input(event):
	if event.is_action_pressed("interact"):
		if !ui.visible and is_mouse_hovering:
			interact()
		elif ui.visible:
			interact()

# Crafting System
func _handle_crafting(delta):
	if FoodNetwork.get_total_food() > 0:
		if !is_crafting and try_consume_ingredients():
			is_crafting = true
			crafting_progress = 0.0
		
		if is_crafting:
			crafting_progress += delta
			progress_bar.value = (crafting_progress / active_recipe.craft_time) * 100
			if crafting_progress >= active_recipe.craft_time:
				complete_crafting()

func try_consume_ingredients() -> bool:
	for item in active_recipe.inputs:
		if !input_storage.has(item) or input_storage[item] < active_recipe.inputs[item]:
			return false

	for item in active_recipe.inputs:
		input_storage[item] -= active_recipe.inputs[item]
	
	update_storage_display()
	update_recipe_buttons()
	return true

func complete_crafting():
	for item in active_recipe.outputs:
		if !output_storage.has(item):
			output_storage[item] = 0
		output_storage[item] += active_recipe.outputs[item]
	
	is_crafting = false
	progress_bar.value = 0
	update_storage_display()
	update_recipe_buttons()

func start_crafting(recipe_name: String):
	active_recipe = recipes[recipe_name]

# UI and Storage Management
func setup_recipe_buttons():
	for recipe_name in recipes:
		recipe_container.add_child(_create_recipe_button(recipe_name))

func update_storage_display():
	_clear_storage_display()
	_display_storage("Input Storage:", input_storage, true)
	_display_storage("Output Storage:", output_storage, false)

func _clear_storage_display():
	for child in storage_container.get_children():
		child.queue_free()

func _display_storage(header: String, storage: Dictionary, is_input: bool):
	var label = Label.new()
	label.text = header
	label.add_theme_font_size_override("font_size", 24)
	storage_container.add_child(label)
	
	for item in storage:
		if !is_input and storage[item] <= 0:
			continue
		storage_container.add_child(_create_storage_item_container(item, storage[item], is_input))

func update_recipe_buttons():
	for button in recipe_container.get_children():
		button.disabled = !is_within_hive_radius


# Inventory transfers
func transfer_item(item: String):
	if output_storage[item] > 0:
		for category in Inventory.categories:
			if Inventory.categories[category].has(item):
				Inventory.add_item(category, item, 1)
				output_storage[item] -= 1
				update_storage_display()
				update_recipe_buttons()
				break

func transfer_from_inventory(item: String):
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

# Building State Management
func set_production_active(active: bool):
	is_within_hive_radius = active
	if active:
		FoodNetwork.register_consumer(self, food_consumption_rate)
		modulate = Color(1, 1, 1, 1)
	else:
		FoodNetwork.unregister_consumer(self)
		modulate = Color(1, 0.5, 0.5, 1)

# Input handling
func interact():
	if current_open_crafter != null and current_open_crafter != self:
		current_open_crafter.ui.hide()
	
	current_open_crafter = self if !ui.visible else null
	ui.visible = !ui.visible
	
	if ui.visible:
		update_storage_display()
		update_recipe_buttons()

func _exit_tree():
	if is_within_hive_radius:
		FoodNetwork.unregister_consumer(self)

# Signal handlers
func _on_mouse_entered():
	is_mouse_hovering = true

func _on_mouse_exited():
	is_mouse_hovering = false

# Helper Functions
func _create_recipe_button(recipe_name: String) -> Button:
	var button = Button.new()
	button.text = recipe_name
	button.add_theme_font_size_override("font_size", 24)
	button.tooltip_text = _get_recipe_tooltip(recipe_name)
	button.pressed.connect(func(): start_crafting(recipe_name))
	return button

func _create_storage_item_container(item: String, amount: int, is_input: bool) -> HBoxContainer:
	var container = HBoxContainer.new()
	
	var label = Label.new()
	label.text = "%s: %d" % [item, amount]
	label.add_theme_font_size_override("font_size", 24)
	
	var transfer_button = Button.new()
	transfer_button.text = "Transfer " + ("From" if is_input else "To") + " Inventory"
	transfer_button.add_theme_font_size_override("font_size", 24)
	transfer_button.pressed.connect(
		func(): transfer_from_inventory(item) if is_input else transfer_item(item)
	)
	
	container.add_child(label)
	container.add_child(transfer_button)
	return container

func _get_recipe_tooltip(recipe_name: String) -> String:
	var tooltip = "Requires:\n"
	for item in recipes[recipe_name].inputs:
		tooltip += "- %s x%d\n" % [item, recipes[recipe_name].inputs[item]]
	tooltip += "\nProduces:\n"
	for item in recipes[recipe_name].outputs:
		tooltip += "- %s x%d\n" % [item, recipes[recipe_name].outputs[item]]
	return tooltip
