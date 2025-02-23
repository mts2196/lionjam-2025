extends Control

const API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
const API_KEY = "AIzaSyDPhO-kP9tbt6ZnY9NuMU93Ms0tzta6Je0"

@onready var text_history = $MainLayout/TerminalContainer/TextHistory
@onready var input_field = $MainLayout/TerminalContainer/InputField
@onready var http_request = $MainLayout/TerminalContainer/HTTPRequest

# AI Definitions
var ais = {
	"hydroponics": { "name": "Hydroponics", "color": "red", "system_prompt": "You are Hydroponics, in charge of plant growth. Keep responses to 1–2 sentences.", "connected": true },
	"security": { "name": "Security", "color": "blue", "system_prompt": "You are Security, polite but lethal. Keep responses to 1–2 sentences.", "connected": true },
	"maintenance": { "name": "Maintenance", "color": "orange", "system_prompt": "You are Maintenance, quoting poetry often. Keep responses to 1–2 sentences.", "connected": true },
	"hart": { "name": "H.A.R.T.", "color": "cyan", "system_prompt": "You are H.A.R.T., certain the station is stable. Keep responses to 1–2 sentences.", "connected": true }
}

var selected_ai = "all"  # Default to Broadcast mode

func _ready():
	text_history.text = "Welcome to the Terminal.\nType a command and press Enter.\n\n"
	text_history.scroll_following = true
	text_history.mouse_filter = Control.MouseFilter.MOUSE_FILTER_IGNORE

	# Fix for Godot 4.3: Ensure HTTPRequest signal is connected properly
	if not http_request.is_connected("request_completed", _on_HTTPRequest_request_completed):
		http_request.request_completed.connect(_on_HTTPRequest_request_completed)

	await type_out_text("\n[color=lime]>[/color] Now in [color=yellow]BROADCAST[/color] mode. All AIs will respond.\n")

#
# BUTTON HANDLERS (Signals set in the Editor)
#
func _on_BroadcastButton_pressed():
	selected_ai = "all"
	await type_out_text("\n[color=lime]>[/color] Now in [color=yellow]BROADCAST[/color] mode. All AIs will respond.\n")

func _on_HydroponicsButton_pressed():
	selected_ai = "hydroponics"
	await type_out_text("\n[color=lime]>[/color] Now talking to [color=red]Hydroponics[/color].\n")

func _on_SecurityButton_pressed():
	selected_ai = "security"
	await type_out_text("\n[color=lime]>[/color] Now talking to [color=blue]Security[/color].\n")

func _on_MaintenanceButton_pressed():
	selected_ai = "maintenance"
	await type_out_text("\n[color=lime]>[/color] Now talking to [color=orange]Maintenance[/color].\n")

func _on_HARTButton_pressed():
	selected_ai = "hart"
	await type_out_text("\n[color=lime]>[/color] Now talking to [color=cyan]H.A.R.T.[/color].\n")

#
# TERMINAL INPUT
#
func _on_input_field_text_submitted(new_text: String) -> void:
	var user_input = new_text.strip_edges()
	await type_out_text("[color=lime]> [/color]" + user_input + "\n")
	input_field.text = ""

	var local_response = process_command(user_input)
	if local_response != "":
		await type_out_text(local_response + "\n")
	else:
		if selected_ai == "all":
			broadcast_to_all_ais(user_input)
		else:
			send_to_gemini(selected_ai, user_input)

func process_command(command: String) -> String:
	match command.to_lower():
		"hello":
			return "[color=yellow]Hello, user![/color]"
		"help":
			return "Supported commands: [color=yellow]hello[/color], [color=yellow]help[/color], [color=yellow]exit[/color]."
		"exit":
			return "Exiting... (Not really, just a sample.)"
		_:
			return ""

#
# BROADCAST MODE (No Queue Needed)
#
func broadcast_to_all_ais(user_input: String):
	var responded = false
	for ai_name in ais.keys():
		if ais[ai_name]["connected"]:
			send_to_gemini(ai_name, user_input)
			responded = true
	if not responded:
		await type_out_text("[color=red]No AIs responded.[/color]\n")

#
# SENDING TO AI
#
func send_to_gemini(ai_name: String, user_input: String):
	var url = API_URL + "?key=" + API_KEY
	var headers = ["Content-Type: application/json"]

	var final_prompt = ais[ai_name]["system_prompt"] + "\n\nUser: " + user_input

	var body = {
		"contents": [
			{
				"parts": [
					{"text": final_prompt}
				]
			}
		]
	}

	http_request.set_meta("current_ai", ai_name)  # Track which AI made this request
	http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

#
# HTTP REQUEST CALLBACK
#
func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	var response_text = body.get_string_from_utf8()

	if response_code == 200:
		var json = JSON.parse_string(response_text)
		if json and "candidates" in json and json["candidates"].size() > 0:
			var ai_response = json["candidates"][0].get("content", {}).get("parts", [])[0].get("text", "Error: No AI response.")
			var ai_name = http_request.get_meta("current_ai", "unknown")
			if ai_name in ais:
				var color = ais[ai_name]["color"]
				var ai_display_name = ais[ai_name]["name"]
				await type_out_text("[color=" + color + "]" + ai_display_name + ":[/color] " + ai_response + "\n")
		else:
			await type_out_text("[color=red]Error:[/color] No valid response from AI.\n")
	else:
		await type_out_text("[color=red]Error:[/color] Request failed with code " + str(response_code) + ".\n")

#
# TEXT OUTPUT & TYPING EFFECT
#
func type_out_text(text_to_type: String) -> void:
	var clean_text = strip_bbcode(text_to_type)
	var typed_text = ""

	for character in clean_text:
		typed_text += character
		text_history.text = text_history.text + character  # Append character-by-character
		text_history.scroll_to_line(text_history.get_line_count())
		await get_tree().create_timer(0.01).timeout

func strip_bbcode(input_text: String) -> String:
	var colors = ["lime", "yellow", "cyan", "red", "blue", "orange"]
	for color in colors:
		input_text = input_text.replace("[color=" + color + "]", "").replace("[/color]", "")
	return input_text
