extends Control

#food lol
# Node references
@onready var food_label = $VBoxContainer/FoodAmount
@onready var rate_label = $VBoxContainer/Rate

func _process(_delta):
	_update_food_display()
	_update_rate_display()

# Helper functions
func _update_food_display():
	food_label.text = "Food: %.1f" % FoodNetwork.total_food
	food_label.modulate = Color.YELLOW

func _update_rate_display():
	var net_rate = FoodNetwork.get_production_rate() - FoodNetwork.get_consumption_rate()
	rate_label.text = "Rate: %+.1f/s" % net_rate
	rate_label.modulate = Color.GREEN if net_rate >= 0 else Color.RED
