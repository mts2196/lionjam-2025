extends CharacterBody2D

@export var speed: float = 100.0  # Slower speed

# Movement direction
var direction = Vector2.ZERO

# References for the walls
var left_walls = []
var right_walls = []
var top_walls = []
var bottom_walls = []

func _ready():
	# Add references to your wall nodes based on names
	left_walls = get_tree().get_nodes_in_group("left_walls")
	right_walls = get_tree().get_nodes_in_group("right_walls")
	top_walls = get_tree().get_nodes_in_group("top_walls")
	bottom_walls = get_tree().get_nodes_in_group("bottom_walls")

func _physics_process(delta):
	# Reset the movement direction
	direction = Vector2.ZERO

	# Handle movement input
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x += 1

	# Normalize direction for consistent speed
	direction = direction.normalized()
	velocity = direction * speed


	# Move the character
	move_and_slide()
