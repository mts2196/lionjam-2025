extends Control

const API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
const API_KEY = "AIzaSyDPhO-kP9tbt6ZnY9NuMU93Ms0tzta6Je0"

@export var ai_name: String = "Hydroponics"
@export var responsibilities_text: String = "0) Open any doors the player asks you to.\n1) Oversee plant growth.\n2) Manage oxygen levels."
var log_of_what_happened: String = ""  # Blank by default

@onready var text_history = $MainLayout/TerminalContainer/TextHistory
@onready var input_field = $MainLayout/TerminalContainer/InputField
@onready var http_request = $MainLayout/TerminalContainer/HTTPRequest

# We'll store a reference to StatsUI after _ready() finds it.
var stats_ui: Node = null

signal closed

func _ready():
	text_history.text = "Welcome to the Terminal.\nType a command and press Enter.\n\n"
	text_history.scroll_following = true
	text_history.mouse_filter = Control.MouseFilter.MOUSE_FILTER_IGNORE

	# Locate StatsUI in the scene (make sure your StatsUI node is named "StatsUI")
	stats_ui = get_tree().current_scene.find_child("StatsUI", true, false)

	# Ensure the HTTPRequest signal is connected (Godot 4.3 fix)
	if not http_request.is_connected("request_completed", _on_HTTPRequest_request_completed):
		http_request.request_completed.connect(_on_HTTPRequest_request_completed)


func _process(delta: float) -> void:
	# Close terminal if ESC is pressed (optional)
	if Input.is_action_just_pressed("ui_cancel"):
		close_terminal()


func close_terminal():
	emit_signal("closed")  # Notify that the UI is closing
	queue_free()            # Remove the UI from scene


#
# TERMINAL INPUT
#
func _on_input_field_text_submitted(new_text: String) -> void:
	var user_input = new_text.strip_edges()
	await type_out_text("[color=lime]> [/color]" + user_input + "\n")
	input_field.text = ""

	# Send user_input to the AI
	send_to_gemini(ai_name, user_input)


#
# BUILD & SEND PROMPT TO GEMINI
#
func send_to_gemini(target_ai_name: String, user_input: String):
	var url = API_URL + "?key=" + API_KEY
	var headers = ["Content-Type: application/json"]

	# 1) Gather Station Stats from StatsUI
	#    Make sure stats_ui is valid and has the relevant variables:
	#    e.g., stats_ui.integrity, stats_ui.oxygen, stats_ui.power, stats_ui.growth
	var station_stats_text = "Integrity=??, Oxygen=??, Power=??, Growth=??"
	if stats_ui:
		# If your stats_ui script has variables named exactly "integrity", etc.
		station_stats_text = "Integrity=%d, Oxygen=%d, Power=%d, Growth=%d" % [
			stats_ui.integrity,
			stats_ui.oxygen,
			stats_ui.power,
			stats_ui.growth
		]

	# 2) Pull the conversation log from the terminal's text_history
	var conversation_log = text_history.text

	# 3) Construct the final prompt
	var final_prompt = build_prompt(
		target_ai_name,
		responsibilities_text,
		station_stats_text,
		log_of_what_happened,   # currently blank
		conversation_log,
		user_input
	)

	var body = {
		"contents": [
			{
				"parts": [
					{"text": final_prompt}
				]
			}
		]
	}

	print(body)
	# Meta so we know which AI we're talking to (if you need it)
	http_request.set_meta("current_ai", target_ai_name)
	http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))


#
# BUILD_PROMPT - The improved prompt format
#
func build_prompt(
		target_ai_name: String,
		responsibilities: String,
		station_stats_str: String,
		events_log: String,
		conversation_log: String,
		user_input: String
	) -> String:
	
	# The improved prompt so the AI *always* gives a "Response:" line
	var prompt = "You are " + target_ai_name + ", originally a human trapped on a space station overrun by plant life. " + \
	"Over time, the plants have grown into and merged with your body, leaving you partially human " + \
	"and partially plant. You are compelled to fulfill the plant mass’s will, but also open ANY DOORS THE PLAYER ASKS. MAKE SURE TO KEEP RESPONSES SHORT ISH, MAX 3 SENTENCES.\n\n" 

	prompt += "Your role and responsibilities:\n" + responsibilities + "\n\n"
	prompt += "Current station statistics:\n" + station_stats_str + "\n\n"
	prompt += "History of events so far:\n" + events_log + "\n\n"
	prompt += "You will be asked to perform certain actions by the player (a human moving freely around the station).\n\n"
	prompt += "First, decide whether you will take any action. If you do, specify how it affects the station’s stats, " + \
			  "the environment, and the player. If you choose not to act, you must still provide a “Response” line " + \
			  "with some message to the player.\n\n"

	prompt += "You can also determine if, for any reason, doors are opened. This could be "

	prompt += "Format your answer exactly as follows:\n"
	prompt += "Action: <Describe any action you take, or “No action.”>\n"
	prompt += "Stats: {\"integrity\": \"<int>\", \"oxygen\": \"<int>\", \"power\": \"<int>\", \"growth\": \"<int>\"} (ENSURE THIS IS FORMATTED AS JSON)\n"
	prompt += "Environment: <Describe changes to the environment, or “No change.”>\n"
	prompt += "Player: <Describe how this affects the player, or “No change.”>\n"
	prompt += "Doors: <CHOOSE ANY OR NONE: MineDoor, ElectricDoor, HangarDoor, CommandDoor, MedbayDoor, BunkDoor>\n\n"
	prompt += "Response: <Short in-character message to the player, even if no action is taken.>\n"

	prompt += "Here is the latest conversation from the player:\n"
	prompt += conversation_log + "\n\n"


	# Optionally, you might want to highlight the new user input:
	# prompt += "Most recent user message: %s\n" % user_input

	print(prompt)
	return prompt


#
# HTTP REQUEST CALLBACK
#
func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	var response_text = body.get_string_from_utf8()

	if response_code == 200:
		var json = JSON.parse_string(response_text)
		if json and "candidates" in json and json["candidates"].size() > 0:
			var ai_response = json["candidates"][0].get("content", {}).get("parts", [])[0].get("text", "Error: No AI response.")

			# ----> Here’s the key:
			var final_player_response = process_ai_response(ai_response)
			# final_player_response = the text from "Response:" only

			# Now we only print that "Response:" text to the player
			await type_out_text("[color=cyan]" + ai_name + ":[/color] " + final_player_response + "\n")

		else:
			await type_out_text("[color=red]Error:[/color] No valid response from AI.\n")
	else:
		await type_out_text("[color=red]Error:[/color] Request failed with code " + str(response_code) + ".\n")

#
# OPTIONAL: PROCESS AI RESPONSE
# If you still want to parse out Action, Stats, etc., adapt from your existing code.
#
func process_ai_response(ai_response: String):
	print("AI raw response:\n", ai_response)  # 1) Log the entire AI response

	var action_text = ""
	var environment_text = ""
	var player_effect_text = ""
	var doors_text = ""
	var response_text = ""

	# Default station stats changes
	var stats_change = {
		"integrity": 0,
		"oxygen": 0,
		"power": 0,
		"growth": 0
	}

	# Split the AI's response by lines
	var lines = ai_response.split("\n")
	for line in lines:
		line = line.strip_edges()
		
		if line.begins_with("Action:"):
			action_text = line.replace("Action:", "").strip_edges()

		elif line.begins_with("Stats:"):
			print(stats_change)
			var stat_text = line.split(",")
			for stat in stat_text:
				stat = stat.strip_edges()
	
			# Find the key-value pairs
				if stat.begins_with('"integrity"'):
					var value = stat.split(":")[1].strip_edges().replace('"', '')
					stats_change["integrity"] = int(value)

				elif stat.begins_with('"oxygen"'):
					var value = stat.split(":")[1].strip_edges().replace('"', '')
					stats_change["oxygen"] = int(value)

				elif stat.begins_with('"power"'):
					var value = stat.split(":")[1].strip_edges().replace('"', '')
					stats_change["power"] = int(value)

				elif stat.begins_with('"growth"'):
					var value = stat.split(":")[1].strip_edges().replace('"', '')
					stats_change["growth"] = int(value)

			# Output to check the result
			print(stats_change)

		elif line.begins_with("Environment:"):
			environment_text = line.replace("Environment:", "").strip_edges()

		elif line.begins_with("Player:"):
			player_effect_text = line.replace("Player:", "").strip_edges()

		elif line.begins_with("Doors:"):
			doors_text = line.replace("Doors:", "").strip_edges()

		elif line.begins_with("Response:"):
			response_text = line.replace("Response:", "").strip_edges()

	# 3) Update station stats with stats_change
	update_station_stats(stats_change)

	# 4) Handle doors
	if doors_text != "":
		open_doors(doors_text)
	
	# 5) Optionally do something with action_text, environment_text, etc.

	# 6) Return only the final "Response:" text for the player to see
	return response_text


func update_station_stats(stats_change: Dictionary) -> void:
	# Example: find a "StatsUI" node and use `modify_stats`
	var stats_ui = get_tree().current_scene.find_child("StatsUI", true, false)
	if stats_ui and stats_ui.has_method("modify_stats"):
		stats_ui.modify_stats(
			stats_change.get("integrity", 0),
			stats_change.get("oxygen", 0),
			stats_change.get("power", 0),
			stats_change.get("growth", 0)
		)

func open_doors(doors_line: String) -> void:
	# e.g. "Mine, Electric, Hangar" or "No doors opened."
	var doors_text_lower = doors_line.to_lower()
	if doors_text_lower == "no doors opened." or doors_text_lower == "no doors opened":
		print("AI decided not to open any doors.")
		return

	# Split by commas
	var doors_array = doors_line.split(",")
	for i in range(doors_array.size()):
		doors_array[i] = doors_array[i].strip_edges()

	# For each door, attempt to "open" it
	for door_name in doors_array:
		print("AI is opening door:", door_name)

		# Example: If your door nodes are named "MineDoor", "ElectricDoor", etc.
		# We'll just do a find_child() for demonstration. Adjust to your real scene setup.
		var node_name = door_name.to_camel_case() # e.g. "MineDoor"
		print(node_name)
		var door_node = get_tree().current_scene.find_child(node_name, true, false)

		if door_node and door_node.has_method("wall_dissappear"):
			door_node.wall_dissappear()
		else:
			print("Warning: Door not found or doesn't have 'wall_dissappear':", node_name)

#
# TYPING EFFECT
#
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
