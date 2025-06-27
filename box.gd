extends Area2D

# Box obstacle - static ground obstacle

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect to player collision if body_entered signal exists
	if has_signal("body_entered"):
		pass # Connection will be handled by the game manager

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Move left with the game speed
	var game_manager = get_parent()
	var move_speed = 2.0  # Base speed for obstacles
	if game_manager.has_method("get") and game_manager.get("speed"):
		move_speed = game_manager.speed # Use game speed directly
	
	position.x -= move_speed * delta
