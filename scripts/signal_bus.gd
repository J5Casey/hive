extends Node

# World Generation & Player Movement
signal player_position_changed(position)  # Sent: Player | Received: WorldGenerator

# Resource System
signal resource_collected(resource_type, amount)  # Sent: Resource | Received: Inventory
signal player_hovering_resource(resource)  # Sent: Resource | Received: Player
signal player_stopped_hovering_resource  # Sent: Resource | Received: Player

# Building System
signal building_selected_from_inventory(building_scene)  # Sent: InventoryUI | Received: BuildingSystem
signal building_placed(building_instance)  # Sent: BuildingSystem | Received: Various Buildings
signal inventory_opened  # Sent: InventoryUI | Received: BuildingSystem, LogisticsSystem

# Food & Hive System
signal food_network_updated(total_food)  # Sent: FoodNetwork | Received: FoodMeter
signal hive_radius_changed(position, radius)  # Sent: Hive | Received: Buildings in radius

# Building Modes
signal destroy_mode_entered  # Sent: BuildingSystem | Received: LogisticsSystem
signal trail_mode_entered  # Sent: LogisticsSystem | Received: BuildingSystem

# World Features
signal request_puddle_removal(position)  # Sent: Landfill | Received: WorldGenerator

# Player State
signal player_died  # Sent: Player | Received: Enemy, Various Systems
signal health_changed(new_health)  # Sent: Player | Received: HealthBar