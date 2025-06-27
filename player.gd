extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -300.0
const GRAVITY = 980.0

@onready var player: CharacterBody2D = $"."
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var FrogJump = $FrogJump
@onready var FrogAttack = $FrogAttack

var is_attacking = false
var can_move = true

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor() and can_move:
		velocity.y = JUMP_VELOCITY
		FrogJump.play()

	# Handle attack
	if Input.is_action_just_pressed("attack") and not is_attacking and can_move:
		is_attacking = true
		
		animated_sprite.play("attack")
		# Wait for animation to finish before returning to normal state
			# Play attack sound once at the start of attack
		if FrogAttack and not FrogAttack.playing:
			FrogAttack.play()
		
		await animated_sprite.animation_finished
		is_attacking = false

	# Skip movement animation changes if attacking
	if not is_attacking and can_move:
		# In endless runner mode, player stays completely still
		# Only handle animations based on vertical movement

		if is_on_floor():
			animated_sprite.play("idle")
		else:
			animated_sprite.play("jump")

		# IMPORTANT: No horizontal movement at all - player stays in exact same X position
		velocity.x = 0
	else:
		# When can't move or attacking, stop all movement
		velocity.x = 0

	move_and_slide()

# Method to enable/disable player movement (called by game manager)
func set_can_move(value: bool):
	can_move = value
	if not can_move:
		velocity = Vector2.ZERO
		
func attack():
	if has_node("AnimatedSprite2D"):
		var sprite = $AnimatedSprite2D
		if sprite.animation != "attack":
			sprite.play("attack")
