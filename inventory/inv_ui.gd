extends Control

var is_open = false
var inventory_resource = preload("res://inventory/player_inv.tres")
@onready var grid_container = $NinePatchRect/GridContainer

func _ready():
	close()
	build_inventory_ui()

func _process(delta):
	if Input.is_action_just_pressed("open_inv"):
		if is_open:
			close()
		else:
			open()

func open():
	self.visible = true
	is_open = true

func close():
	self.visible = false
	is_open = false

func build_inventory_ui():
	# Clear any existing slots (if needed)
	grid_container.clear()

	# Load the slot scene
	var slot_scene = preload("res://inventory/inv_ui_slot.tscn")

	# Get the inventory items
	var inventory_items = inventory_resource.Items
	var inventory_size = inventory_items.size()

	# Set the number of columns for GridContainer (adjust as needed)
	grid_container.columns = 10  # For example, 10 columns

	# Create slots based on the inventory size

	for item in inventory_items:
		var slot_instance = slot_scene.instantiate()
		slot_instance.set_item(item)
		grid_container.add_child(slot_instance)
