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

func _ready():
	$CollectArea.shape.radius = 32  # Adjust this value as needed
	connect("area_entered", _on_area_entered)
	connect("area_exited", _on_area_exited)

func _on_area_entered(area):
	if area.is_in_group("player"):
		highlight_resource()

func _on_area_exited(area):
	if area.is_in_group("player"):
		unhighlight_resource()

func highlight_resource():
	# Add visual feedback when player is in range
	$Sprite2D.modulate = Color(1.2, 1.2, 1.2)  # Slightly brighten the sprite

func unhighlight_resource():
	# Remove visual feedback
	$Sprite2D.modulate = Color(1, 1, 1)  # Reset to normal color

func collect_resource():
	# This function will be called when the player decides to collect the resource
	SignalBus.emit_signal("resource_collected", resource_type, amount)
	queue_free()
	
func set_resource_type(new_type):
	resource_type = new_type
	$Sprite2D.texture = resource_textures[resource_type]
