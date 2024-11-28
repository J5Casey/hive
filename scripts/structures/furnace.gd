extends Area2D

@export var building_name = "FURNACE"

var recipes = {
	"IRON_INGOT (x2)": {
		"inputs": {
			"IRON": 1,
			"COAL": 1
		},
		"outputs": {
			"IRON_INGOT": 2
		},
		"craft_time": 3.0
	}
}

var storage = {
	"IRON_INGOT": 0
}

var current_recipe = null
var crafting_progress = 0.0
var is_crafting = false
var is_mouse_hovering = false

static var current_open_furnace: Area2D = null


@onready var ui = $CanvasLayer/FurnaceUI
@onready var recipe_container = $CanvasLayer/FurnaceUI/Panel/Crafting/RecipeContainer
@onready var progress_bar = $CanvasLayer/FurnaceUI/Panel/Crafting/ProgressBar
@onready var storage_container = $CanvasLayer/FurnaceUI/Panel/Storage/StorageContainer
@onready var close_button = $CanvasLayer/FurnaceUI/Panel/CloseButton
func _ready():
	ui.hide()
	setup_recipe_buttons()
	close_button.pressed.connect(func(): ui.hide())
	update_storage_display()

func interact():
	if current_open_furnace != null and current_open_furnace != self:
		current_open_furnace.ui.hide()
	
	current_open_furnace = self if !ui.visible else null
	ui.visible = !ui.visible
	
	if ui.visible:
		update_storage_display()
		update_recipe_buttons()

func setup_recipe_buttons():
	for recipe_name in recipes:
		var recipe_button = Button.new()
		recipe_button.text = recipe_name
		recipe_button.add_theme_font_size_override("font_size", 24)
		
		# Create tooltip text
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
			var found = false
			for category in Inventory.categories:
				if Inventory.categories[category].has(item):
					if Inventory.get_item_amount(category, item) >= recipe.inputs[item]:
						found = true
						break
			if !found:
				can_craft = false
				break
		button.disabled = !can_craft

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

func start_crafting(recipe_name):
	if recipes.has(recipe_name):
		current_recipe = recipes[recipe_name]
		if try_consume_ingredients():
			is_crafting = true
			crafting_progress = 0.0
		
func try_consume_ingredients():
	# Check if we have all ingredients across any category
	for item in current_recipe.inputs:
		var found = false
		for category in Inventory.categories:
			if Inventory.categories[category].has(item):
				if Inventory.get_item_amount(category, item) >= current_recipe.inputs[item]:
					found = true
					break
		if !found:
			return false

	# Consume the ingredients from their respective categories
	for item in current_recipe.inputs:
		for category in Inventory.categories:
			if Inventory.categories[category].has(item):
				Inventory.add_item(category, item, -current_recipe.inputs[item])
				break

	return true

func _process(delta):
	if is_crafting and current_recipe:
		crafting_progress += delta
		progress_bar.value = (crafting_progress / current_recipe.craft_time) * 100
		if crafting_progress >= current_recipe.craft_time:
			complete_crafting()

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
