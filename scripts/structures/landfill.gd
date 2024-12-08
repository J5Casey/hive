extends Area2D

# Configuration
@export var building_name = "LANDFILL"
@export var is_ghost = false

func _ready():
	if not is_ghost:
		remove_puddle()
		queue_free()

# Core functionality 
func remove_puddle():
	SignalBus.emit_signal("request_puddle_removal", global_position)
