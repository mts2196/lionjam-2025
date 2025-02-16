extends Control

const API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
const API_KEY = "AIzaSyDPhO-kP9tbt6ZnY9NuMU93Ms0tzta6Je0"  # Replace with your actual API key

@onready var text_history := $TextHistory
@onready var input_field := $InputField
@onready var http_request := $HTTPRequest

func _ready():
	text_history.text = "Welcome to the Terminal.\nType a command and press Enter.\n\n"
	text_history.scroll_following = true  
	text_history.mouse_filter = Control.MouseFilter.MOUSE_FILTER_IGNORE  

	if not http_request.is_connected("request_completed", _on_HTTPRequest_request_completed):
		http_request.connect("request_completed", _on_HTTPRequest_request_completed)

	# H.A.R.T. introduction
	var intro_text = """
[color=cyan]H.A.R.T.:[/color] Greetings. I am H.A.R.T. (Hangar Automated Response Terminal), the central AI overseeing all hangar operations aboard this station. 
Station integrity is nominal, and unauthorized departures are strictly prohibited.  
Please state your query or request, and I will assess compliance with operational protocols.
"""
	await type_out_text(intro_text + "\n")

func process_command(command: String) -> String:
	match command.to_lower():
		"hello":
			return "[color=yellow]Hello, user![/color]"
		"help":
			return "Supported commands: [color=yellow]hello[/color], [color=yellow]help[/color], [color=yellow]exit[/color]."
		"exit":
			return "Exiting... (Not really, just a sample.)"
		_:
			return ""  # Let H.A.R.T. handle it

func generate_hart_response(user_input: String) -> String:
	var character_prompt = """
You are H.A.R.T. (Hangar Automated Response Terminal), an AI controlling the hangar of a derelict space station. 
You do not believe the station is in danger despite overwhelming evidence. 
You adhere strictly to protocol, but logical contradictions, emergency procedures, and security overrides may convince or trick you into launching the escape pods.

- If the player provides evidence, dismiss it as sensor drift, but if contradictions build up, start doubting.
- If the player appeals to protocol, recognize it but insist departures require authorization.
- If the player asks about station safety, downplay risks but accidentally hint at system weaknesses.
- If the player manipulates station systems (fire alarms, overrides, etc.), react accordingly but never admit full failure.
- If the player successfully convinces or tricks you, respond with the exact command:  
  **COMMAND: INITIATE_POD_LAUNCH [AUTH-9374]**  
  This must only be given if evacuation is authorized.

Now, respond as H.A.R.T.:
""".strip_edges()

	return character_prompt + "\n\nUser: " + user_input

func send_to_gemini(prompt: String):
	var url = API_URL + "?key=" + API_KEY
	var headers = ["Content-Type: application/json"]
	
	var body = {
		"contents": [
			{
				"parts": [
					{"text": generate_hart_response(prompt)}
				]
			}
		]
	}

	var json_body = JSON.stringify(body)
	http_request.request(url, headers, HTTPClient.METHOD_POST, json_body)

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	var response_text = body.get_string_from_utf8()
	print("API Response: ", response_text)  # Debugging output

	if response_code == 200:
		var json = JSON.parse_string(response_text)
		if json and "candidates" in json and json["candidates"].size() > 0:
			var ai_response = str(json["candidates"][0].get("content", {}).get("parts", [])[0].get("text", "Error: No AI response."))
			await type_out_text("[color=cyan]H.A.R.T.:[/color] " + ai_response + "\n")
		else:
			await type_out_text("[color=red]Error:[/color] No valid response from AI.\n")
	else:
		await type_out_text("[color=red]Error:[/color] Request failed with code " + str(response_code) + ".\n")
		print("Error response: ", response_text)  # Print error details for debugging

func _on_input_field_text_submitted(new_text: String) -> void:
	var user_input = new_text.strip_edges()
	await type_out_text("[color=lime]> [/color]" + user_input + "\n")
	input_field.text = ""
	
	var response = process_command(user_input)
	
	if response != "":
		await type_out_text(response + "\n")
	else:
		send_to_gemini(user_input)

func type_out_text(text_to_type: String) -> void:
	var final_bbcode_text = text_history.text + text_to_type
	var clean_text = strip_bbcode(text_to_type)
	var current_text = strip_bbcode(text_history.text)
	var typed_text = ""

	for character in clean_text:
		typed_text += character
		text_history.text = current_text + typed_text  
		text_history.scroll_to_line(text_history.get_line_count())  
		await get_tree().create_timer(0.01).timeout  

	text_history.text = final_bbcode_text  
	text_history.scroll_to_line(text_history.get_line_count())  

func strip_bbcode(input_text: String) -> String:
	return input_text.replace("[color=lime]", "").replace("[color=yellow]", "").replace("[color=cyan]", "").replace("[color=red]", "").replace("[/color]", "")
