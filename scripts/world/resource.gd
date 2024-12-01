extends Area2D

enum ResourceType { WOOD, COAL, STONE, IRON, GOLD }

@export var resource_type = ResourceType.WOOD
@export var amount: int = 1
var harvestable = false  # Indicates if the resource is within harvesting range

@export var harvest_time: float = 2.0  # Time required to harvest
var is_harvesting: bool = false
var harvest_progress: float = 0.0

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
	ResourceType.WOOD: "WOOD",
	ResourceType.COAL: "COAL",
	ResourceType.STONE: "STONE",
	ResourceType.IRON: "IRON",
	ResourceType.GOLD: "GOLD"
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
	
	# Configure the progress bar
	$HarvestUI/HarvestProgressBar.visible = false
	$HarvestUI/HarvestProgressBar.min_value = 0
	$HarvestUI/HarvestProgressBar.max_value = harvest_time
	$HarvestUI/HarvestProgressBar.value = 0

func _process(delta):
	if is_harvesting:
		harvest_progress += delta
		$HarvestUI/HarvestProgressBar.value = harvest_progress
		
		# Get the position above the resource in world coordinates
		var progress_pos = global_position + Vector2(0, -40)
		
		# Convert world position to screen coordinates
		var screen_pos = get_viewport_transform() * progress_pos
		
		# Update progress bar position
		$HarvestUI/HarvestProgressBar.position = screen_pos
		$HarvestUI/HarvestProgressBar.size = Vector2(60, 10)
		
		if harvest_progress >= harvest_time:
			is_harvesting = false
			harvest_progress = 0.0
			$HarvestUI/HarvestProgressBar.visible = false
			collect_resource()

func _on_collect_area_entered(area):
	if area.is_in_group("player"):
		highlight_resource()

func _on_collect_area_exited(area):
	if area.is_in_group("player"):
		unhighlight_resource()
		cancel_harvesting()

func _on_hitbox_mouse_entered():
	SignalBus.emit_signal("player_hovering_resource", self)

func _on_hitbox_mouse_exited():
	SignalBus.emit_signal("player_stopped_hovering_resource")

func highlight_resource():
	$HighlightSprite2D.visible = true
	harvestable = true  # Resource is now harvestable

func unhighlight_resource():
	$HighlightSprite2D.visible = false
	harvestable = false  # Resource is no longer harvestable

func start_harvesting():
	if is_harvesting:
		return
	is_harvesting = true
	harvest_progress = 0.0
	$HarvestUI/HarvestProgressBar.value = 0
	$HarvestUI/HarvestProgressBar.visible = true

func cancel_harvesting():
	if not is_harvesting:
		return
	is_harvesting = false
	harvest_progress = 0.0
	$HarvestUI/HarvestProgressBar.visible = false
	$HarvestUI/HarvestProgressBar.value = 0.0

func collect_resource():
	SignalBus.emit_signal("resource_collected", resource_names[resource_type], amount)


func set_resource_type(new_type):
	resource_type = new_type
	$BaseSprite2D.texture = resource_textures[resource_type]
	$HighlightSprite2D.texture = resource_highlight_textures[resource_type]
