extends Area2D

@export var win_sound: AudioStreamPlayer2D
@export var win_image: Sprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	win_image.visible = false # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_Area2D_body_entered(body: Node) -> void:
	if body.name == "Elon Pusk":  # Check if the player's name is Elon Pusk
		# Play the sound
		win_sound.play()

		# Show the "Win" image
		win_image.visible = true


func _on_body_entered(body: Node2D) -> void:
		if body.name == "Elon Pusk":  # Check if the player's name is Elon Pusk
			# Play the sound
			win_sound.play()

			# Show the "Win" image
			win_image.visible = true
