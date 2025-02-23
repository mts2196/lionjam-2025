extends Area2D

signal interacted  # Signal for interaction

func _ready():
	connect("interacted", Callable(self, "_on_interacted"))

func _on_interacted():
	print("Terminal Activated!")  # Replace with actual logic

func _input_event(viewport, event, shape_idx):
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		emit_signal("interacted")
