extends Area2D

# Bee movement variables
var base_speed: float = 2.5  # Much slower
var hover_amplitude: float = 20.0
var hover_frequency: float = 4.0
var time_passed: float = 0.0
var start_y: float
var direction_change_timer: float = 0.0
var direction_change_interval: float = 2.0
var vertical_direction: int = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	start_y = position.y
	# Connect to player collision if body_entered signal exists
	if has_signal("body_entered"):
		pass # Connection will be handled by the game manager

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time_passed += delta
	direction_change_timer += delta
	
	# Move left at a reasonable speed
	var game_manager = get_parent()
	var move_speed = base_speed
	if game_manager.has_method("get") and game_manager.get("speed"):
		move_speed = base_speed + game_manager.speed # Simple addition, no multiplication
	
	position.x -= move_speed * delta
	
	# Add hovering movement pattern (more erratic than fly)
	position.y = start_y + sin(time_passed * hover_frequency) * hover_amplitude
	
	# Change direction occasionally for more bee-like behavior
	if direction_change_timer >= direction_change_interval:
		vertical_direction *= -1
		direction_change_timer = 0.0
		direction_change_interval = randf_range(1.5, 3.0)
	
	# Add additional vertical movement
	position.y += vertical_direction * 10.0 * delta
	
	# Add slight rotation based on movement
	rotation = sin(time_passed * hover_frequency) * 0.15


func _on_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
