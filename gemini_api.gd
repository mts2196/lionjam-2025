extends Node

const API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateText"
const API_KEY = "AIzaSyDPhO-kP9tbt6ZnY9NuMU93Ms0tzta6Je0"  # Replace with your actual API key

@onready var http_request = $HTTPRequest

func send_message(prompt: String):
	var url = API_URL + "?key=" + API_KEY
	var headers = ["Content-Type: application/json"]
	var body = {
		"prompt": {"text": prompt}
	}

	var json_body = JSON.stringify(body)
	http_request.request(url, headers, HTTPClient.METHOD_POST, json_body)

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and "candidates" in json:
			print("AI Response: ", json["candidates"][0]["output"])
		else:
			print("Error: No response from AI")
	else:
		print("Error: Request failed with code ", response_code)
