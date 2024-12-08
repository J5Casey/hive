extends Area2D

# Configuration
@export var building_name = "STORAGE_CRATE"

# State and Storage
var is_mouse_hovering = false
var is_within_hive_radius = false
var storage = {}
static var current_open_storage: Area2D = null

# Node References
@onready var ui = $CanvasLayer/StorageUI
@onready var storage_container = $CanvasLayer/StorageUI/Panel/StorageContainer
@onready var close_button = $CanvasLayer/StorageUI/Panel/CloseButton

# Core Functions
func _ready():
	ui.hide()
	close_button.pressed.connect(func(): ui.hide())
	update_storage_display()

# UI and Storage Management
func update_storage_display():
	_clear_storage_display()
	_display_storage_items()

func _clear_storage_display():
	for child in storage_container.get_children():
		child.queue_free()

func _display_storage_items():
	for item in storage:
		if storage[item] > 0:
			storage_container.add_child(_create_storage_item_container(item))

func _create_storage_item_container(item: String) -> HBoxContainer:
	var container = HBoxContainer.new()
	
	var label = Label.new()
	label.text = "%s: %d" % [item, storage[item]]
	label.add_theme_font_size_override("font_size", 24)
	
	var transfer_button = Button.new()
	transfer_button.text = "Transfer"
	transfer_button.add_theme_font_size_override("font_size", 24)
	transfer_button.pressed.connect(func(): transfer_item(item))
	
	container.add_child(label)
	container.add_child(transfer_button)
	return container

# Inventory Transfers
func transfer_item(item):
	if storage[item] > 0:
		for category in Inventory.categories:
			if Inventory.categories[category].has(item):
				Inventory.add_item(category, item, 1)
				storage[item] -= 1
				update_storage_display()
				break

# Building State Management
func set_production_active(active: bool):
	is_within_hive_radius = active

func interact():
	if current_open_storage != null and current_open_storage != self:
		current_open_storage.ui.hide()
	
	current_open_storage = self if !ui.visible else null
	ui.visible = !ui.visible
	
	if ui.visible:
		update_storage_display()

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
