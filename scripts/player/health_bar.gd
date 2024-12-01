extends Control

@onready var progress_bar = $ProgressBar

func _ready():
	SignalBus.health_changed.connect(_on_health_changed)
	progress_bar.self_modulate = Color.GREEN

func _on_health_changed(new_health: float):
	progress_bar.value = new_health

	# Update color based on health percentage
	if new_health > 60:
		progress_bar.self_modulate = Color.GREEN
	elif new_health > 30:
		progress_bar.self_modulate = Color.YELLOW
	else:
		progress_bar.self_modulate = Color.RED
