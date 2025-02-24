extends CharacterBody2D

@export var speed: float = 50.0  # Player movement speed

@onready var sprite = $AnimatedSprite2D
@onready var footsteps = $walking
@onready var music = $backmusic
var is_moving = false

func _ready():
	music.play()

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
		sprite.play("left")
	elif Input.is_action_pressed("move_right"):
		direction.x += 1
		sprite.play("right")
		
	else:
		sprite.stop()

	# Normalize direction for consistent speed (diagonal movement is not faster)
	direction = direction.normalized()
	
	if direction.length() > 0:
		if not is_moving:
			is_moving = true
			footsteps.play()
	else:
		if is_moving:
			is_moving = false
			footsteps.stop()
	
	# Set the velocity to move the character in the specified direction
	velocity = direction * speed

	# Move the character with the calculated velocity
	move_and_slide()
