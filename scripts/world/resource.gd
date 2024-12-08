extends Area2D

# Configuration
enum ResourceType { WOOD, COAL, STONE, IRON, GOLD }
@export var resource_type = ResourceType.WOOD
@export var amount: int = 1
@export var harvest_time: float = 2.0

# State tracking
var harvestable = false
var is_harvesting: bool = false
var harvest_progress: float = 0.0

# Resource definitions
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

# Node References
@onready var base_sprite = $BaseSprite2D
@onready var highlight_sprite = $HighlightSprite2D
@onready var harvest_progress_bar = $HarvestUI/HarvestProgressBar
@onready var collect_area = $CollectArea

func _ready():
	_connect_signals()
	_setup_resource()
	call_deferred("setup_textures")

func _process(delta):
	if is_harvesting:
		_handle_harvesting(delta)

# Setup Functions
func _connect_signals():
	collect_area.connect("area_entered", _on_collect_area_entered)
	collect_area.connect("area_exited", _on_collect_area_exited)
	connect("mouse_entered", _on_hitbox_mouse_entered)
	connect("mouse_exited", _on_hitbox_mouse_exited)

func _setup_resource():
	base_sprite.texture = resource_textures[resource_type]
	highlight_sprite.texture = resource_highlight_textures[resource_type]
	highlight_sprite.visible = false
	
	harvest_progress_bar.visible = false
	harvest_progress_bar.min_value = 0
	harvest_progress_bar.max_value = harvest_time
	harvest_progress_bar.value = 0

func setup_textures():
	base_sprite.texture = resource_textures[resource_type]
	highlight_sprite.texture = resource_highlight_textures[resource_type]
	highlight_sprite.visible = false

# Harvesting System
func _handle_harvesting(delta):
	harvest_progress += delta
	harvest_progress_bar.value = harvest_progress
	_update_progress_bar_position()
	
	if harvest_progress >= harvest_time:
		_complete_harvesting()

func _update_progress_bar_position():
	var progress_pos = global_position + Vector2(0, -40)
	var screen_pos = get_viewport_transform() * progress_pos
	harvest_progress_bar.position = screen_pos
	harvest_progress_bar.size = Vector2(60, 10)

func _complete_harvesting():
	is_harvesting = false
	harvest_progress = 0.0
	harvest_progress_bar.visible = false
	collect_resource()

# Resource State Management
func start_harvesting():
	if is_harvesting:
		return
	is_harvesting = true
	harvest_progress = 0.0
	harvest_progress_bar.value = 0
	harvest_progress_bar.visible = true

func cancel_harvesting():
	if not is_harvesting:
		return
	is_harvesting = false
	harvest_progress = 0.0
	harvest_progress_bar.visible = false
	harvest_progress_bar.value = 0.0

func collect_resource():
	SignalBus.emit_signal("resource_collected", resource_names[resource_type], amount)

# Visual Feedback
func highlight_resource():
	highlight_sprite.visible = true
	harvestable = true

func unhighlight_resource():
	highlight_sprite.visible = false
	harvestable = false

# Signal Handlers
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

# Resource Type Management
func set_resource_type(new_type):
	resource_type = new_type
	# Wait until node is ready before setting textures
	if not is_node_ready():
		await ready
	base_sprite.texture = resource_textures[resource_type]
	highlight_sprite.texture = resource_highlight_textures[resource_type]
