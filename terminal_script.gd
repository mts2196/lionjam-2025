extends Control

const API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
const API_KEY = "AIzaSyDPhO-kP9tbt6ZnY9NuMU93Ms0tzta6Je0"

@onready var text_history = $MainLayout/TerminalContainer/TextHistory
@onready var input_field = $MainLayout/TerminalContainer/InputField
@onready var http_request = $MainLayout/TerminalContainer/HTTPRequest

signal closed

# AI Definitions
var ais = {
	"hydroponics": {
		"name": "Hydroponics",
		"color": "red",
		"system_prompt": "You are Hydroponics, in charge of plant growth. Keep responses to 1–2 sentences.",
		"connected": true
	},
	"security": {
		"name": "Security",
		"color": "blue",
		"system_prompt": "You are Security, polite but lethal. Keep responses to 1–2 sentences.",
		"connected": true
	},
	"maintenance": {
		"name": "Maintenance",
		"color": "orange",
		"system_prompt": "You are Maintenance, quoting poetry often. Keep responses to 1–2 sentences.",
		"connected": true
	},
	"hart": {
		"name": "H.A.R.T.",
		"color": "cyan",
		"system_prompt": "You are H.A.R.T., certain the station is stable. Keep responses to 1–2 sentences.",
		"connected": true
	}
}

var selected_ai = "all"  # Default to Broadcast mode

# Station Stats
var station_stats = {
	"integrity": 100,
	"oxygen": 100,
	"power": 100,
	"growth": 0
}

# Queue for broadcasting to multiple AIs
var broadcast_queue: Array = []
var broadcast_user_input: String = ""

func _ready():
	# Disable player movement while this terminal is open
	set_player_can_move(false)

	text_history.text = "Welcome to the Terminal.\nType a command and press Enter.\n\n"
	text_history.scroll_following = true
	text_history.mouse_filter = Control.MouseFilter.MOUSE_FILTER_IGNORE

	# Ensure HTTPRequest signal is connected
	if not http_request.is_connected("request_completed", _on_HTTPRequest_request_completed):
		http_request.request_completed.connect(_on_HTTPRequest_request_completed)

	await type_out_text("\n[color=lime]>[/color] Now in [color=yellow]BROADCAST[/color] mode. All AIs will respond.\n")


func _process(_delta):
	# Press ESC to close
	if Input.is_action_just_pressed("ui_cancel"):
		close_terminal()


func close_terminal():
	# Re-enable player movement
	set_player_can_move(true)

	emit_signal("closed")
	queue_free()


#--------------------------------------------------------------------------
# Helpers to disable/enable player movement by toggling Player.can_move
#--------------------------------------------------------------------------
func set_player_can_move(enable: bool) -> void:
	var player = get_tree().current_scene.find_child("Player", true, false)
	if player and player.has_method("_physics_process"):  # Ensure it's a valid node
		player.can_move = enable  # Assume 'can_move' exists in Player.gd


#--------------------------------------------------------------------------
# TERMINAL INPUT
#--------------------------------------------------------------------------
func _on_input_field_text_submitted(new_text: String) -> void:
	var user_input = new_text.strip_edges()
	await type_out_text("[color=lime]> [/color]" + user_input + "\n")
	input_field.text = ""

	if selected_ai == "all":
		setup_broadcast_to_all_ais(user_input)
	else:
		send_to_gemini(selected_ai, user_input)


#--------------------------------------------------------------------------
# BROADCAST MODE (serializing requests)
#--------------------------------------------------------------------------
func setup_broadcast_to_all_ais(user_input: String):
	broadcast_queue.clear()
	broadcast_user_input = user_input

	# Collect all AIs that are "connected"
	for ai_name in ais.keys():
		if ais[ai_name]["connected"]:
			broadcast_queue.push_back(ai_name)

	if broadcast_queue.size() == 0:
		await type_out_text("[color=red]No AIs responded.[/color]\n")
		return

	# Start with the first AI
	broadcast_next()


func broadcast_next():
	if broadcast_queue.size() == 0:
		# No more AIs to process
		return

	var next_ai = broadcast_queue.pop_front()
	send_to_gemini(next_ai, broadcast_user_input)


#--------------------------------------------------------------------------
# SENDING TO AI
#--------------------------------------------------------------------------
func send_to_gemini(ai_name: String, user_input: String):
	var url = API_URL + "?key=" + API_KEY
	var headers = ["Content-Type: application/json"]

	var final_prompt = ais[ai_name]["system_prompt"] + "\n\nUser: " + user_input + "\n\n" + \
		"AI: Decide whether to take action based on the player's request. If action is taken, format your response as follows:\n" + \
		"Action: <What action is taken>\n" + \
		"Stats: {integrity: <int>, oxygen: <int>, power: <int>, growth: <int>}\n" + \
		"Environment: <Describe changes to the environment>\n" + \
		"Player: <Describe how this affects the player>\n\n" + \
		"Otherwise, simply respond as usual."

	var body = {
		"contents": [
			{
				"parts": [
					{"text": final_prompt}
				]
			}
		]
	}

	http_request.set_meta("current_ai", ai_name)
	http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))


#--------------------------------------------------------------------------
# HTTP REQUEST CALLBACK
#--------------------------------------------------------------------------
func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	var ai_name = http_request.get_meta("current_ai", "unknown")
	var response_text = body.get_string_from_utf8()

	if response_code == 200:
		var json = JSON.parse_string(response_text)
		if json and "candidates" in json and json["candidates"].size() > 0:
			var ai_response = json["candidates"][0].get("content", {}).get("parts", [])[0].get("text", "Error: No AI response.")
			if ai_name in ais:
				var color = ais[ai_name]["color"]
				var ai_display_name = ais[ai_name]["name"]

				# Filter out raw lines (Action:, Stats:, etc.) when printing
				var cleaned_response = filter_raw_response(ai_response)
				await type_out_text("[color=" + color + "]" + ai_display_name + ":[/color] " + cleaned_response + "\n")

				process_ai_response(ai_response)
		else:
			await type_out_text("[color=red]Error:[/color] No valid response from AI.\n")
	else:
		await type_out_text("[color=red]Error:[/color] Request failed with code " + str(response_code) + ".\n")

	# Move on to the next AI in the queue
	broadcast_next()


#--------------------------------------------------------------------------
# FILTER OUT "Action:", "Stats:", "Environment:", "Player:" lines (for display)
#--------------------------------------------------------------------------
func filter_raw_response(full_text: String) -> String:
	var lines = full_text.split("\n")
	var display_text = ""

	for line in lines:
		var trimmed = line.strip_edges()
		if trimmed.begins_with("Action:"):
			continue
		if trimmed.begins_with("Stats:"):
			continue
		if trimmed.begins_with("Environment:"):
			continue
		if trimmed.begins_with("Player:"):
			continue
		display_text += trimmed + "\n"

	return display_text.strip_edges()


#--------------------------------------------------------------------------
# PROCESS AI RESPONSE (Parses Action, Stats, Environment, and Player Impact)
#--------------------------------------------------------------------------
func process_ai_response(ai_response: String):
	var action = ""
	var stats_change = { "integrity": 0, "oxygen": 0, "power": 0, "growth": 0 }
	var environment = ""
	var player_effect = ""

	# Parse AI lines
	for line in ai_response.split("\n"):
		line = line.strip_edges()
		if line.begins_with("Action:"):
			action = line.replace("Action:", "").strip_edges()
		elif line.begins_with("Stats:"):
			var stats_text = line.replace("Stats:", "").strip_edges()
			var parsed_stats = JSON.parse_string(stats_text)
			if parsed_stats:
				stats_change = parsed_stats
		elif line.begins_with("Environment:"):
			environment = line.replace("Environment:", "").strip_edges()
		elif line.begins_with("Player:"):
			player_effect = line.replace("Player:", "").strip_edges()

	# Apply station stats changes
	for key in station_stats.keys():
		station_stats[key] = clamp(station_stats[key] + stats_change.get(key, 0), 0, 100)

	# Update main UI (StatsUI)
	var stats_ui = get_tree().current_scene.find_child("StatsUI", true, false)
	if stats_ui and stats_ui.has_method("modify_stats"):
		stats_ui.modify_stats(
			stats_change.get("integrity", 0),
			stats_change.get("oxygen", 0),
			stats_change.get("power", 0),
			stats_change.get("growth", 0)
		)


	# Print results
	if action != "":
		await type_out_text("\n[color=yellow]Action Taken:[/color] " + action)
	if stats_change:
		await type_out_text("\n[color=green]Station Updated:[/color] Integrity: %d, Oxygen: %d, Power: %d, Growth: %d" %
			[station_stats["integrity"], station_stats["oxygen"], station_stats["power"], station_stats["growth"]])
	if environment != "":
		await type_out_text("\n[color=lightblue]Environment Changed:[/color] " + environment)
	if player_effect != "":
		await type_out_text("\n[color=magenta]Effect on Player:[/color] " + player_effect)


#--------------------------------------------------------------------------
# TYPING EFFECT
#--------------------------------------------------------------------------
func type_out_text(text_to_type: String) -> void:
	var clean_text = strip_bbcode(text_to_type)
	for character in clean_text:
		text_history.text += character
		text_history.scroll_to_line(text_history.get_line_count())
		await get_tree().create_timer(0.01).timeout


func strip_bbcode(input_text: String) -> String:
	var colors = ["lime","yellow","cyan","red","blue","orange","lightblue","magenta","green"]
	for c in colors:
		input_text = input_text.replace("[color=" + c + "]", "").replace("[/color]", "")
	return input_text
