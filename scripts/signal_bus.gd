extends Node

signal player_position_changed(position)

signal resource_collected(resource_type, amount)

signal player_hovering_resource(resource)
signal player_stopped_hovering_resource

signal building_selected_from_inventory(building_scene)
signal building_placed(building_instance)

signal inventory_opened

signal food_network_updated(total_food)
signal hive_radius_changed(position, radius)

signal destroy_mode_entered
signal trail_mode_entered

signal request_puddle_removal(position) 

signal player_died 