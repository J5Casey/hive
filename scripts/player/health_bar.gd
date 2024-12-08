extends Control

# Node references
@onready var progress_bar = $ProgressBar

# Color thresholds
const HIGH_HEALTH_THRESHOLD = 60
const LOW_HEALTH_THRESHOLD = 30

func _ready():
	SignalBus.health_changed.connect(_on_health_changed)
	_set_initial_color()

# Helper functions
func _set_initial_color():
	progress_bar.self_modulate = Color.GREEN

func _update_bar_color(health: float):
	if health > HIGH_HEALTH_THRESHOLD:
		progress_bar.self_modulate = Color.GREEN
	elif health > LOW_HEALTH_THRESHOLD:
		progress_bar.self_modulate = Color.YELLOW
	else:
		progress_bar.self_modulate = Color.RED

# Signal handlers
func _on_health_changed(new_health: float):
	progress_bar.value = new_health
	_update_bar_color(new_health)
