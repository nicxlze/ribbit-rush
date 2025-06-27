extends Area2D

# Fly movement variables
var base_speed: float = 3.0  # Much slower
var wave_amplitude: float = 30.0
var wave_frequency: float = 3.0
var time_passed: float = 0.0
var start_y: float

# Called when the node enters the scene tree for the first time.
func _ready():
	start_y = position.y
	# Connect to player collision if body_entered signal exists
	if has_signal("body_entered"):
		pass # Connection will be handled by the game manager

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time_passed += delta
	
	# Move left at a reasonable speed
	var game_manager = get_parent()
	var move_speed = base_speed
	if game_manager.has_method("get") and game_manager.get("speed"):
		move_speed = base_speed + game_manager.speed # Simple addition, no multiplication
	
	position.x -= move_speed * delta
	
	# Add wave-like vertical movement for more dynamic flight pattern
	position.y = start_y + sin(time_passed * wave_frequency) * wave_amplitude
	
	# Optional: Add slight rotation based on vertical movement
	rotation = sin(time_passed * wave_frequency) * 0.1


func _on_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
