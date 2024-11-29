extends Area2D

@export var building_name = "STORAGE_CRATE"

var storage = {}
var is_mouse_hovering = false

static var current_open_storage: Area2D = null

@onready var ui = $CanvasLayer/StorageUI
@onready var storage_container = $CanvasLayer/StorageUI/Panel/StorageContainer
@onready var close_button = $CanvasLayer/StorageUI/Panel/CloseButton

func _ready():
	ui.hide()
	close_button.pressed.connect(func(): ui.hide())
	update_storage_display()

func interact():
	if current_open_storage != null and current_open_storage != self:
		current_open_storage.ui.hide()
	
	current_open_storage = self if !ui.visible else null
	ui.visible = !ui.visible
	
	if ui.visible:
		update_storage_display()

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
