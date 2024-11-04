extends Control

var item_labels = {}
var recipe_buttons = {}

func _ready():
	visible = false
	setup_category_displays()
	setup_crafting_panel()
	var recipe_buttons = {}

func setup_crafting_panel():
	for recipe_name in Crafting.recipes:
		var button = Button.new()
		button.text = recipe_name
		button.name = recipe_name
		button.pressed.connect(_on_recipe_pressed.bind(recipe_name))
		$HBoxContainer/CraftingPanel/VBoxContainer.add_child(button)
		recipe_buttons[recipe_name] = button
	
	# Update crafting buttons state in process
	update_recipe_buttons()

func update_recipe_buttons():
	for recipe_name in recipe_buttons:
		var button = recipe_buttons[recipe_name]
		button.disabled = not Crafting.can_craft(recipe_name)
		
		# Show recipe requirements on hover
		var requirements_text = "\nRequires:"
		for category in Crafting.recipes[recipe_name]:
			if category == "output_category":
				continue
			for resource in Crafting.recipes[recipe_name][category]:
				var amount = Crafting.recipes[recipe_name][category][resource]
				requirements_text += "\n%s: %d" % [resource, amount]
		button.tooltip_text = requirements_text

func _on_recipe_pressed(recipe_name: String):
	print("Button pressed for: ", recipe_name)
	Crafting.craft_item(recipe_name)

func setup_category_displays():
	for category in Inventory.categories:
		var category_container = VBoxContainer.new()
		category_container.name = category
		
		var category_label = Label.new()
		category_label.text = category
		category_label.set("theme_override_colors/font_color", Color(0, 0, 0))
		category_container.add_child(category_label)
		
		$HBoxContainer/Categories.add_child(category_container)
		
		for item_name in Inventory.categories[category]:
			var label = Label.new()
			label.name = item_name
			label.set("theme_override_colors/font_color", Color(0, 0, 0))
			category_container.add_child(label)
			item_labels[item_name] = label

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
