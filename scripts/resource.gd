extends Area2D

enum ResourceType { WOOD, COAL, STONE, IRON, GOLD }

@export var resource_type = ResourceType.WOOD
@export var amount: int = 1

var resource_textures = {
	ResourceType.WOOD: preload("res://assets/sprites/resources/wood.png"),
	ResourceType.COAL: preload("res://assets/sprites/resources/coal.png"),
	ResourceType.STONE: preload("res://assets/sprites/resources/stone.png"),
	ResourceType.IRON: preload("res://assets/sprites/resources/iron.png"),
	ResourceType.GOLD: preload("res://assets/sprites/resources/gold.png")
}

var resource_highlight_textures = {
	ResourceType.WOOD: preload("res://assets/sprites/resources/wood_highlight.png"),
	ResourceType.COAL: preload("res://assets/sprites/resources/coal_highlight.png"),
	ResourceType.STONE: preload("res://assets/sprites/resources/stone_highlight.png"),
	ResourceType.IRON: preload("res://assets/sprites/resources/iron_highlight.png"),
	ResourceType.GOLD: preload("res://assets/sprites/resources/gold_highlight.png")
}

var resource_names = {
	ResourceType.WOOD: "wood",
	ResourceType.COAL: "coal",
	ResourceType.STONE: "stone",
	ResourceType.IRON: "iron",
	ResourceType.GOLD: "gold"
}

func _ready():
	$CollectArea.connect("area_entered", _on_collect_area_entered)
	$CollectArea.connect("area_exited", _on_collect_area_exited)
	connect("mouse_entered", _on_hitbox_mouse_entered)
	connect("mouse_exited", _on_hitbox_mouse_exited)
	
	# Set up both regular and highlight textures
	$BaseSprite2D.texture = resource_textures[resource_type]
	$HighlightSprite2D.texture = resource_highlight_textures[resource_type]
	$HighlightSprite2D.visible = false

func _on_collect_area_entered(area):
	if area.is_in_group("player"):
		highlight_resource()

func _on_collect_area_exited(area):
	if area.is_in_group("player"):
		unhighlight_resource()

func _on_hitbox_mouse_entered():
	SignalBus.emit_signal("player_hovering_resource", resource_type)
	print("hovering over ", resource_names[resource_type])

func _on_hitbox_mouse_exited():
	SignalBus.emit_signal("player_stopped_hovering_resource")
	print("not hovering")

func _on_hitbox_area_entered(area):
	if area.is_in_group("player"):
		SignalBus.emit_signal("player_hovering_resource", resource_type)

func _on_hitbox_area_exited(area):
	if area.is_in_group("player"):
		SignalBus.emit_signal("player_stopped_hovering_resource")

func highlight_resource():
	$HighlightSprite2D.visible = true

func unhighlight_resource():
	$HighlightSprite2D.visible = false

func collect_resource():
	# This function will be called when the player decides to collect the resource
	SignalBus.emit_signal("resource_collected", resource_type, amount)
	
func set_resource_type(new_type):
	resource_type = new_type
	$BaseSprite2D.texture = resource_textures[resource_type]
	$HighlightSprite2D.texture = resource_highlight_textures[resource_type]
