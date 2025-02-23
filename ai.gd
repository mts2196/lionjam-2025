extends Node

# Reference to station stats (set in _ready)
@onready var stats = get_tree().current_scene.find_child("StatsUI", true, false)

# Processes a player's message and determines AI actions
func process_player_message(message: String):
	print("\n--- AI Processing Message ---")
	print("Player said: " + message)

	# Determine AI response
	var response = decide_action(message)

	# Print what happens
	print("\n--- AI Response ---")
	print("Action Taken: " + response.action)
	print("Effect on Station Stats: " + str(response.stats_change))
	print("Environmental Change: " + response.environment_change)
	print("Effect on Player: " + response.player_effect)

	# Apply station stats change (if applicable)
	if response.stats_change:
		stats.modify_stats(
			response.stats_change.get("integrity", 0),
			response.stats_change.get("oxygen", 0),
			response.stats_change.get("power", 0),
			response.stats_change.get("growth", 0)
		)

# AI decision-making function
func decide_action(player_message: String):
	var result = {
		"action": "No action taken",
		"stats_change": {},
		"environment_change": "No environmental change",
		"player_effect": "Nothing happens"
	}

	player_message = player_message.to_lower()

	# Example: Player requests to restore power
	if "restore power" in player_message or "turn on power" in player_message:
		result.action = "Re-routing emergency reserves to power grid."
		result.stats_change = {"power": 20}
		result.environment_change = "Lights flicker on, terminals become operational."
		result.player_effect = "The room is illuminated, reducing risk of injury."

	# Example: Player requests to purge overgrowth
	elif "purge plants" in player_message or "clear growth" in player_message:
		if stats.growth > 50:
			result.action = "Deploying automated flamethrowers to clear growth."
			result.stats_change = {"growth": -30, "oxygen": -10}  # Burned plants reduce O2
			result.environment_change = "Parts of the station are now burned and charred."
			result.player_effect = "Acrid smoke fills the corridors, making breathing difficult."
		else:
			result.action = "Not enough overgrowth detected for a purge."
			result.environment_change = "No visible change."
			result.player_effect = "Nothing happens."

	# Example: Player requests AI status check
	elif "status report" in player_message or "how is the station" in player_message:
		result.action = "Performing diagnostic scan."
		result.environment_change = "HUD updates with latest station statistics."
		result.player_effect = "You receive a real-time station report."

	# Example: Player requests air circulation
	elif "increase oxygen" in player_message or "restore air" in player_message:
		if stats.power > 30:
			result.action = "Reactivating life support systems."
			result.stats_change = {"oxygen": 15, "power": -10}  # Uses power to restore O2
			result.environment_change = "Air vents hum as fresh oxygen is circulated."
			result.player_effect = "You feel the air quality improve."
		else:
			result.action = "Insufficient power to restart oxygen systems."
			result.player_effect = "The AI refuses to comply."

	return result
