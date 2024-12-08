extends Area2D

# Configuration
@export var building_name = "FURNACE"

# Recipe definitions
var recipes = {
	"IRON_INGOT (x2)": {
		"inputs": {"IRON": 1, "COAL": 1},
		"outputs": {"IRON_INGOT": 2},
		"craft_time": 3.0
	},
	"REFINED_STONE (x2)": {
		"inputs": {"STONE": 2, "COAL": 1},
		"outputs": {"REFINED_STONE": 2},
		"craft_time": 2.0
	}
}

# State and Storage
var active_recipe = null
var crafting_progress = 0.0
var is_crafting = false
var is_mouse_hovering = false
var is_within_hive_radius = false
var input_storage = {}
var output_storage = {}
static var current_open_furnace: Area2D = null

# Node References
@onready var ui = $CanvasLayer/FurnaceUI
@onready var recipe_container = $CanvasLayer/FurnaceUI/Panel/Crafting/RecipeContainer
@onready var progress_bar = $CanvasLayer/FurnaceUI/Panel/Crafting/ProgressBar
@onready var storage_container = $CanvasLayer/FurnaceUI/Panel/Storage/StorageContainer
@onready var close_button = $CanvasLayer/FurnaceUI/Panel/CloseButton

# Core Functions
func _ready():
	ui.hide()
	close_button.pressed.connect(func(): ui.hide())
	setup_recipe_buttons()
	update_storage_display()

func _process(delta):
	update_recipe_buttons()
	if active_recipe:
		_handle_crafting(delta)

# Crafting System
func _handle_crafting(delta):
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
	update_storage_display()

func start_crafting(recipe_name):
	active_recipe = recipes[recipe_name]

# UI and Storage Management
func setup_recipe_buttons():
	for recipe_name in recipes:
		recipe_container.add_child(_create_recipe_button(recipe_name))

func update_recipe_buttons():
	for button in recipe_container.get_children():
		button.disabled = !is_within_hive_radius

func update_storage_display():
	_clear_storage_display()
	_display_input_storage()
	_display_output_storage()

func _clear_storage_display():
	for child in storage_container.get_children():
		child.queue_free()

func _display_input_storage():
	var input_label = Label.new()
	input_label.text = "Input Storage:"
	input_label.add_theme_font_size_override("font_size", 24)
	storage_container.add_child(input_label)
	
	var required_inputs = ["IRON", "COAL"]
	for item in required_inputs:
		var amount = input_storage[item] if input_storage.has(item) else 0
		storage_container.add_child(_create_storage_item_container(item, amount, true))

func _display_output_storage():
	var output_label = Label.new()
	output_label.text = "Output Storage:"
	output_label.add_theme_font_size_override("font_size", 24)
	storage_container.add_child(output_label)
	
	for item in output_storage:
		if output_storage[item] > 0:
			storage_container.add_child(_create_storage_item_container(item, output_storage[item], false))

# Building State Management
func set_production_active(active: bool):
	is_within_hive_radius = active

func interact():
	if current_open_furnace != null and current_open_furnace != self:
		current_open_furnace.ui.hide()
	
	current_open_furnace = self if !ui.visible else null
	ui.visible = !ui.visible
	
	if ui.visible:
		update_storage_display()
		update_recipe_buttons()

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

# Inventory Transfers
func transfer_item(item):
	if output_storage[item] > 0:
		for category in Inventory.categories:
			if Inventory.categories[category].has(item):
				Inventory.add_item(category, item, 1)
				output_storage[item] -= 1
				update_storage_display()
				break

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

# Input Handling
func _input(event):
	if event.is_action_pressed("interact"):
		if !ui.visible and is_mouse_hovering:
			interact()
		elif ui.visible:
			interact()

# Signal Handlers
func _on_mouse_entered():
	is_mouse_hovering = true

func _on_mouse_exited():
	is_mouse_hovering = false

func _on_trail_button_pressed():
	LogisticsSystem.start_trail_placement(self)
