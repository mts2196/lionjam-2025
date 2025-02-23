extends CharacterBody2D

@export var speed: float = 50.0  # Player movement speed

var direction = Vector2.ZERO

var can_move = true

func _physics_process(delta):

	if not can_move:
		return

	var direction = Vector2.ZERO

	# Handle movement input
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x += 1

	# Normalize direction for consistent speed (diagonal movement is not faster)
	direction = direction.normalized()

	# Set the velocity to move the character in the specified direction
	velocity = direction * speed

	# Move the character with the calculated velocity
	move_and_slide()
