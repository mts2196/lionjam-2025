extends Area2D

@export var ai_name: String = "hydroponics"  # AI name (e.g., "security", "maintenance", "hart")
@export var terminal_ui_scene: PackedScene  # Drag & drop TerminalUI.tscn in the editor

var player_inside = false  # Tracks if the player is inside this terminal's area
var ui_instance: Control = null  # Reference to the spawned terminal UI

func _process(_delta):
	if player_inside and Input.is_action_just_pressed("interact"):
		open_terminal_ui()
		print("Player interacted with the terminal.")

func _on_body_entered(body: Node2D) -> void:
	print("entered:", body.name)

	# Check if the player entered
	if body.is_in_group("player"):  # Make sure the player is in the "player" group
		player_inside = true

func _on_body_exited(body: Node2D) -> void:
	print("exited:", body.name)

	# Check if the player exited
	if body.is_in_group("player"):
		player_inside = false

func open_terminal_ui():
	if ui_instance == null:  # Prevent multiple instances
		# Check if terminal_ui_scene is assigned
		if terminal_ui_scene == null:
			print("ERROR: terminal_ui_scene is NOT set in the editor!")
			return

		print("Instantiating Terminal UI...")
		ui_instance = terminal_ui_scene.instantiate()
		
		# Assign AI name to the UI, if supported
		if "active_ai" in ui_instance:
			ui_instance.active_ai = ai_name
		else:
			print("WARNING: Terminal UI does not have 'active_ai' variable.")

		# Add to UI layer
		var ui_layer = get_tree().current_scene.find_child("UI", true, false)
		if ui_layer:
			print("Adding terminal UI to UI layer...")
			ui_layer.add_child(ui_instance)
		else:
			print("UI layer not found, adding to current scene...")
			get_tree().current_scene.add_child(ui_instance)

		# Wait a frame for layout updates
		await get_tree().process_frame  

		# Center the UI
		var screen_size = get_viewport_rect().size
		ui_instance.global_position = (screen_size / 2) - (ui_instance.size / 2)

		# Connect close signal
		ui_instance.connect("closed", Callable(self, "close_terminal_ui"))
		print("Terminal UI opened successfully.")

func close_terminal_ui():
	if ui_instance:
		print("Closing terminal UI...")
		ui_instance.queue_free()
		ui_instance = null
