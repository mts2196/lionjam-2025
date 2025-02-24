extends CharacterBody2D

@export var speed: float = 50.0  # Player movement speed

@onready var sprite = $AnimatedSprite2D

var direction = Vector2.ZERO
func _physics_process(delta):
	# Reset direction each frame
	direction = Vector2.ZERO

	# Handle movement input
	if Input.is_action_pressed("move_up"):
		direction.y -= 1 
		sprite.play("backward")
	elif Input.is_action_pressed("move_down"):
		direction.y += 1
		sprite.play("forward")
	elif Input.is_action_pressed("move_left"):
		direction.x -= 1
		
	elif Input.is_action_pressed("move_right"):
		direction.x += 1
		sprite.play("right")
		
	else:
		sprite.stop()

	# Normalize direction for consistent speed (diagonal movement is not faster)
	direction = direction.normalized()
	
	
	# Set the velocity to move the character in the specified direction
	velocity = direction * speed

	# Move the character with the calculated velocity
	move_and_slide()
