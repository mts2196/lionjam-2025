extends Area2D

var player_inside = false  # Tracks if the player is inside the terminal's area

@export var terminal_ui_scene: PackedScene  # Drag & drop TerminalUI.tscn in the editor
var ui_instance = null  # Reference to the spawned terminal UI


func _process(_delta):
	if player_inside and Input.is_action_just_pressed("interact"):
		open_terminal_ui()
		print("Player interacted with the terminal.")


func _on_body_entered(body: Node2D) -> void:
	print("entered")
	if body.name == "Player":
		player_inside = true


func _on_body_exited(body: Node2D) -> void:
	print("exited")
	if body.name == "Player":  # Ensure it's the player
		player_inside = false

func open_terminal_ui():
	if ui_instance == null:  # Prevent multiple instances
		ui_instance = terminal_ui_scene.instantiate()
		# Find the UI layer and add the terminal there
		var ui_layer = get_tree().current_scene.find_child("UI", true, false)
		if ui_layer:
			ui_layer.add_child(ui_instance)  # Add terminal UI to the correct layer
		else:
			get_tree().current_scene.add_child(ui_instance)  # Fallback (shouldn't be needed)
		# Wait a frame so layout updates correctly
		await get_tree().process_frame  
		# Ensure terminal is centered
		var screen_size = get_viewport_rect().size
		ui_instance.global_position = (screen_size / 2) - (ui_instance.size / 2)
		ui_instance.connect("closed", Callable(self, "close_terminal_ui"))  # If UI has a close signal

func close_terminal_ui():
	if ui_instance:
		ui_instance.queue_free()
		ui_instance = null
