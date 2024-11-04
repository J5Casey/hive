extends Control

var item_labels = {}
var recipe_buttons = {}

func _ready():
	visible = false
	setup_category_tabs()
	setup_crafting_panel()

func setup_category_tabs():
	var tab_container = $InventoryPanel/TabContainer
	
	for category in Inventory.categories:
		var tab = VBoxContainer.new()
		tab.name = category
		tab.add_theme_constant_override("separation", 10)
		tab.set("theme_override_constants/margin_left", 10)
		tab.set("theme_override_constants/margin_top", 10)
		tab_container.add_child(tab)
		
		for item_name in Inventory.categories[category]:
			var label = Label.new()
			label.name = item_name
			label.set("theme_override_colors/font_color", Color(1, 1, 1))
			tab.add_child(label)
			item_labels[item_name] = label			
func setup_crafting_panel():
	for recipe_name in Crafting.recipes:
		var container = VBoxContainer.new()
		container.add_theme_constant_override("separation", 5)
		
		var button = Button.new()
		button.text = recipe_name
		button.name = recipe_name
		button.pressed.connect(_on_recipe_pressed.bind(recipe_name))
		container.add_child(button)
		
		var progress = ProgressBar.new()
		progress.name = "Progress"
		progress.max_value = 1.0
		progress.value = 0
		progress.show_percentage = false
		container.add_child(progress)
		
		$CraftingPanel/VBoxContainer.add_child(container)
		
		# Store both the button and progress bar references
		var recipe_data = {}
		recipe_data["button"] = button
		recipe_data["progress"] = progress
		recipe_buttons[recipe_name] = recipe_data
func _process(_delta):
	update_inventory_display()
	update_recipe_buttons()
	
	if Input.is_action_just_pressed("open_inv"):
		visible = not visible
		
func update_inventory_display():
	for category in Inventory.categories:
		for item_name in Inventory.categories[category]:
			var amount = Inventory.get_item_amount(category, item_name)
			if item_labels.has(item_name):
				item_labels[item_name].text = "%s: %d" % [item_name.capitalize(), amount]

func _on_recipe_pressed(recipe_name: String):
	print("Button pressed for: ", recipe_name)
	if await Crafting.craft_item(recipe_name):
		print("Crafted: ", recipe_name)

func update_recipe_buttons():
	for recipe_name in recipe_buttons:
		var recipe_data = recipe_buttons[recipe_name]
		recipe_data["button"].disabled = not Crafting.can_craft(recipe_name)
		recipe_data["progress"].value = Crafting.get_craft_progress(recipe_name)
		
		var requirements_text = "\nRequires:"
		for category in Crafting.recipes[recipe_name]:
			if category == "output_category" or category == "craft_time":
				continue
			for resource in Crafting.recipes[recipe_name][category]:
				var amount = Crafting.recipes[recipe_name][category][resource]
				requirements_text += "\n%s: %d" % [resource, amount]
		recipe_data["button"].tooltip_text = requirements_text
