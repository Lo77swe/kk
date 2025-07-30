extends CharacterBody3D

@export var walk_speed := 5.0
@export var sprint_speed := 10.0
@export var jump_velocity := 4.5
@export var gravity := 9.8
@export var mouse_sensitivity := 0.1

@export var max_stamina := 100.0
@export var stamina_drain_rate := 25.0   # stamina drained per second while sprinting
@export var stamina_recover_rate := 15.0 # stamina recovered per second when not sprinting
@export var min_stamina_to_sprint := 5.0 # minimum stamina required to sprint

var current_stamina := max_stamina
var camera: Camera3D
var stamina_bar: ProgressBar

func _ready():
	camera = $Camera3D
	stamina_bar = get_node("CanvasLayer/StaminaBar")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		camera.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -89, 89)

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
	var direction = Vector3.ZERO
	var forward = -transform.basis.z
	var right = transform.basis.x

	if Input.is_action_pressed("move_forward"):
		direction += forward
	if Input.is_action_pressed("move_backward"):
		direction -= forward
	if Input.is_action_pressed("move_left"):
		direction -= right
	if Input.is_action_pressed("move_right"):
		direction += right

	direction = direction.normalized()

	# Check if player tries to sprint (holding sprint + moving)
	var is_trying_to_sprint = Input.is_action_pressed("sprint") and direction != Vector3.ZERO
	var can_sprint = current_stamina > min_stamina_to_sprint
	var is_sprinting = is_trying_to_sprint and can_sprint

	var current_speed: float
	if is_sprinting:
		current_speed = sprint_speed
		current_stamina -= stamina_drain_rate * delta
		if current_stamina < 0:
			current_stamina = 0
	else:
		current_speed = walk_speed
		current_stamina += stamina_recover_rate * delta
		if current_stamina > max_stamina:
			current_stamina = max_stamina

	# Update stamina bar UI
	if stamina_bar:
		stamina_bar.value = current_stamina

	# Movement velocity
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed

	# Gravity and jumping
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
		else:
			velocity.y = 0

	move_and_slide()
