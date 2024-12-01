extends Control

@onready var food_label = $VBoxContainer/FoodAmount
@onready var rate_label = $VBoxContainer/Rate

func _process(_delta):
	food_label.text = "Food: %.1f" % FoodNetwork.total_food
	food_label.modulate = Color.REBECCA_PURPLE
	# Not Becca, Rebecca, because she was a big girl
	var net_rate = FoodNetwork.get_production_rate() - FoodNetwork.get_consumption_rate()
	rate_label.text = "Rate: %+.1f/s" % net_rate
	rate_label.modulate = Color.GREEN if net_rate >= 0 else Color.RED
