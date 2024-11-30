extends Area2D

@export var building_name = "LANDFILL"
@export var is_ghost = false

func _ready():
	if not is_ghost:
		remove_puddle()
		queue_free() 

func remove_puddle():
	var position = global_position
	SignalBus.emit_signal("request_puddle_removal", position)
