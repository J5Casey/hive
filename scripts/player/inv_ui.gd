extends Control

# UI element tracking
var item_labels = {}
var recipe_buttons = {}

func _ready():
	visible = false
	_setup_ui_elements()

func _process(_delta):
	_update_displays()
	_handle_inventory_toggle()

# Setup functions
func _setup_ui_elements():
	setup_category_tabs()
	setup_crafting_panel()
	setup_building_buttons()

func setup_category_tabs():
	var tab_container = $InventoryPanel/TabContainer
	tab_container.add_theme_font_size_override("font_size", 32)
	
	for category in Inventory.categories:
		var tab = _create_category_tab(category)
		tab_container.add_child(tab)

func setup_building_buttons():
	var machines_tab = $InventoryPanel/TabContainer/Machines
	
	for item_name in Inventory.categories["Machines"]:
		var container = _create_building_container(item_name)
		machines_tab.add_child(container)

func setup_crafting_panel():
	for recipe_name in Crafting.recipes:
		var container = _create_recipe_container(recipe_name)
		$CraftingPanel/VBoxContainer.add_child(container)

# UI Creation helpers
func _create_category_tab(category: String) -> VBoxContainer:
	var tab = VBoxContainer.new()
	tab.name = category
	tab.add_theme_constant_override("separation", 10)
	tab.set("theme_override_constants/margin_left", 10)
	tab.set("theme_override_constants/margin_top", 10)
	
	var header = _create_category_header(category)
	tab.add_child(header)
	
	_add_item_labels(tab, category)
	return tab

func _create_category_header(category: String) -> Label:
	var label = Label.new()
	label.text = category + "\n_________________"
	label.add_theme_font_size_override("font_size", 32)
	return label

func _add_item_labels(tab: VBoxContainer, category: String):
	for item_name in Inventory.categories[category]:
		var label = Label.new()
		label.name = item_name
		label.add_theme_font_size_override("font_size", 24)
		tab.add_child(label)
		item_labels[item_name] = label

func _create_building_container(item_name: String) -> HBoxContainer:
	var container = HBoxContainer.new()
	
	var label = Label.new()
	label.name = item_name
	label.add_theme_font_size_override("font_size", 24)
	container.add_child(label)
	item_labels[item_name] = label
	
	var build_button = _create_build_button(item_name)
	container.add_child(build_button)
	
	return container

func _create_build_button(item_name: String) -> Button:
	var button = Button.new()
	button.text = "Build"
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(_on_build_pressed.bind(item_name))
	return button

func _create_recipe_container(recipe_name: String) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	
	var button = _create_recipe_button(recipe_name)
	container.add_child(button)
	
	var progress = _create_progress_bar()
	container.add_child(progress)
	
	recipe_buttons[recipe_name] = {
		"button": button,
		"progress": progress
	}
	
	return container

func _create_recipe_button(recipe_name: String) -> Button:
	var button = Button.new()
	button.text = recipe_name
	button.name = recipe_name
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(_on_recipe_pressed.bind(recipe_name))
	return button

func _create_progress_bar() -> ProgressBar:
	var progress = ProgressBar.new()
	progress.name = "Progress"
	progress.max_value = 1.0
	progress.value = 0
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, 10)
	progress.modulate = Color(0.2, 0.8, 0.2)
	return progress

# Update functions
func _update_displays():
	update_inventory_display()
	update_recipe_buttons()

func update_inventory_display():
	for category in Inventory.categories:
		for item_name in Inventory.categories[category]:
			if item_labels.has(item_name):
				var amount = Inventory.get_item_amount(category, item_name)
				item_labels[item_name].text = "%s: %d" % [item_name.capitalize(), amount]

func update_recipe_buttons():
	for recipe_name in recipe_buttons:
		var recipe_data = recipe_buttons[recipe_name]
		recipe_data["button"].disabled = not Crafting.can_craft(recipe_name)
		recipe_data["progress"].value = Crafting.get_craft_progress(recipe_name)
		recipe_data["button"].tooltip_text = _get_requirements_text(recipe_name)

# Input handlers
func _handle_inventory_toggle():
	if Input.is_action_just_pressed("open_inv"):
		visible = not visible
		if visible:
			SignalBus.emit_signal("inventory_opened")

# Signal handlers
func _on_build_pressed(building_name: String):
	if Inventory.building_scenes.has(building_name):
		SignalBus.emit_signal("building_selected_from_inventory", 
							Inventory.building_scenes[building_name])
		visible = false

func _on_recipe_pressed(recipe_name: String):
	if await Crafting.craft_item(recipe_name):
		print("Crafted: ", recipe_name)

# Helper functions
func _get_requirements_text(recipe_name: String) -> String:
	var text = "\nRequires:"
	for category in Crafting.recipes[recipe_name]:
		if category == "output_category" or category == "craft_time":
			continue
		for resource in Crafting.recipes[recipe_name][category]:
			var amount = Crafting.recipes[recipe_name][category][resource]
			text += "\n%s: %d" % [resource, amount]
	return text
