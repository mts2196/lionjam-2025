extends CharacterBody2D

@export var speed: float = 200.0  # Player movement speed

func _physics_process(delta):
	var direction = Vector2.ZERO

	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x += 1

	direction = direction.normalized()  # Normalize for consistent speed diagonally
	velocity = direction * speed
	move_and_slide()

var nearby_terminal: Area2D = null

func _process(delta):
	if Input.is_action_just_pressed("interact") and nearby_terminal:
		nearby_terminal.emit_signal("interacted")

func _on_body_entered(body):
	if body is Area2D:
		nearby_terminal = body

func _on_body_exited(body):
	if body == nearby_terminal:
		nearby_terminal = null
