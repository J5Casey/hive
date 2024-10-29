extends Control

var resource_labels = {}

func _ready():
	#Off by default
	visible = false
	
	# Access the resources dictionary from the Inventory singleton
	var resources = Inventory.resources

	# Dynamically create labels for each resource
	for resource_name in resources.keys():
		var label = Label.new()
		label.name = resource_name
		label.set("theme_override_colors/font_color", Color(0, 0, 0))
		$ScrollContainer/VBoxContainer.add_child(label)
		resource_labels[resource_name] = label


func _process(delta):
	update_inventory_display()
	
	#Toggle inventory visibility
	if Input.is_action_just_pressed("open_inv"):
		visible = not visible
	
func update_inventory_display():
	var resources = Inventory.resources
	for resource_name in resources.keys():
		var amount = resources[resource_name]
		var label = resource_labels[resource_name]
		label.text = "%s: %d" % [resource_name.capitalize(), amount]
