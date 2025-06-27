extends Node

# --- Preload obstacles and enemies ---
var fly_scene = preload("res://scenes/fly.tscn")
var bee_scene = preload("res://scenes/bee.tscn")
var rock_scene = preload("res://scenes/rock.tscn")
var box_scene = preload("res://scenes/box.tscn")
var obstacle_types := [rock_scene, box_scene]
var enemy_types := [fly_scene, bee_scene]
var obstacles: Array = []
var enemies: Array = []
var enemy_heights := [500, 510, 520, 530]

# --- Game State ---
var game_started := false
var game_over := false
var score := 0
var points := 0
var high_score := 0
var distance_traveled := 0.0
var difficulty := 0
var last_obs_x := 0.0

# --- Constants ---
const SCORE_MODIFIER = 5
const START_SPEED = 2.0
const MAX_SPEED = 8.0
const SPEED_MODIFIER = 50000.0
const PLAYER_START_POS := Vector2i(150, 540)
const CAM_START_POS := Vector2i(576, 400)
const VIEWPORT_WIDTH = 1024
const VIEWPORT_HEIGHT = 640
const GROUND_Y = 564
const MIN_OBSTACLE_SPACING = 400
const MAX_OBSTACLE_SPACING = 600

# --- Speed and movement ---
var speed: float = START_SPEED
var screen_size: Vector2
var ground_height: int

# --- Node references ---
@onready var player: CharacterBody2D
@onready var camera: Camera2D
@onready var ground: StaticBody2D = find_child("Ground", true, false)
@onready var game_over_ui = get_node_or_null("GameOver")
@onready var restart_button: Button
@onready var bg_music = $bg_music


var player_start_pos = PLAYER_START_POS
var camera_start_pos = CAM_START_POS

func _ready():
	player = get_parent().get_node("Player") as CharacterBody2D
	if player and player.has_node("Camera2D"):
		camera = player.get_node("Camera2D") as Camera2D

	screen_size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	if ground:
		ground_height = ground.get_node("Sprite2D").texture.get_height()

	setup_game_over_ui()
	load_high_score()
	call_deferred("setup_game")

func load_high_score():
	var config = ConfigFile.new()
	if config.load("user://save_data.cfg") == OK:
		high_score = config.get_value("Scores", "high_score", 0)

func save_high_score():
	var config = ConfigFile.new()
	config.set_value("Scores", "high_score", high_score)
	config.save("user://save_data.cfg")

func check_high_score():
	if score > high_score:
		high_score = score
		save_high_score()
	

	# HUD display
	if has_node("HUD") and $HUD.has_node("HighScoreLabel"):
		var label = $HUD.get_node("HighScoreLabel")
		label.text = "HIGH SCORE: " + str(int(high_score / SCORE_MODIFIER))

	# GameOver UI display
	if game_over_ui:
		var high_score_label = game_over_ui.find_child("*HighScore*", true, false)
		if high_score_label and high_score_label is Label:
			high_score_label.text = "HIGH SCORE: " + str(int(high_score / SCORE_MODIFIER))

func setup_game_over_ui():
	game_over_ui = get_parent().get_node_or_null("GameOver")
	if not game_over_ui:
		print("❌ GameOver UI not found.")
		return

	game_over_ui.visible = false

	restart_button = game_over_ui.find_child("Button", true, false)
	if not restart_button:
		restart_button = game_over_ui.find_child("RestartButton", true, false)
	if not restart_button:
		for child in game_over_ui.get_children():
			if child is Button:
				restart_button = child
				break

	if restart_button and not restart_button.pressed.is_connected(_on_restart_button_pressed):
		restart_button.pressed.connect(_on_restart_button_pressed)
		print("✅ Restart button connected.")

func setup_game():
	setup_starting_positions()
	show_start_screen()

func _process(delta):
	if game_started and not game_over:
		speed = min(START_SPEED + (score / SPEED_MODIFIER), MAX_SPEED)
		adjust_difficulty()
		generate_obstacles()
		generate_enemies()

		if player:
			player.position.x += speed * 200 * delta
			distance_traveled += speed * 200 * delta

		score += speed * delta * 60
		show_score()
		check_high_score()  # (Optional: Real-time high score)

		if player and ground and player.position.x - ground.position.x > screen_size.x * 1.5:
			ground.position.x += screen_size.x

		remove_offscreen_objects()
	elif not game_started and not game_over:
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump"):
			start_game()

func _input(event):
	if not game_started and not game_over and Input.is_action_just_pressed("move_right"):
		start_game()
	elif game_over and (Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept")):
		restart_game()

func generate_obstacles():
	if not player:
		return

	var should_spawn = obstacles.is_empty()
	if not should_spawn:
		var rightmost_x = 0
		for obs in obstacles:
			if is_instance_valid(obs):
				rightmost_x = max(rightmost_x, obs.position.x)
		should_spawn = rightmost_x < player.position.x + screen_size.x

	if should_spawn:
		var obs_type = obstacle_types[randi() % obstacle_types.size()]
		var obs = obs_type.instantiate()
		var sprite = obs.get_node("Sprite2D")
		var obs_y = GROUND_Y - (sprite.texture.get_height() * sprite.scale.y / 2) - -3
		var spacing = randi_range(MIN_OBSTACLE_SPACING, MAX_OBSTACLE_SPACING)
		if obstacles.is_empty():
			spacing += 600
		else:
			spacing += randi_range(-100, 150)

		var obs_x = last_obs_x + spacing
		last_obs_x = obs_x
		add_obstacle(obs, obs_x, obs_y)


func generate_enemies():
	if not player or score <= 50 or randi() % 100 >= 4:
		return
	var enemy_type = enemy_types[randi() % enemy_types.size()]
	var enemy = enemy_type.instantiate()
	var x = player.position.x + screen_size.x + randi_range(200, 400)
	var y = enemy_heights[randi() % enemy_heights.size()]
	add_enemy(enemy, x, y)

func add_obstacle(obs, x, y):
	obs.position = Vector2(x, y)
	if obs.has_signal("body_entered"):
		obs.body_entered.connect(hit_obstacle)
	add_child(obs)
	obstacles.append(obs)

func add_enemy(enemy, x, y):
	enemy.position = Vector2(x, y)
	if enemy is Area2D and enemy.has_signal("body_entered"):
		enemy.body_entered.connect(func(body): hit_enemy(body, enemy))
	add_child(enemy)
	enemies.append(enemy)
	if player and player.has_method("attack"):
		player.attack()

func remove_obstacle(obs):
	if is_instance_valid(obs):
		obs.queue_free()
		obstacles.erase(obs)

func remove_enemy(enemy):
	if is_instance_valid(enemy):
		enemy.queue_free()
		enemies.erase(enemy)

func remove_offscreen_objects():
	for obs in obstacles.duplicate():
		if is_instance_valid(obs) and obs.position.x < player.position.x - screen_size.x:
			score += 500
			remove_obstacle(obs)
	for enemy in enemies.duplicate():
		if is_instance_valid(enemy) and enemy.position.x < player.position.x - screen_size.x:
			score += 1000
			remove_enemy(enemy)

func hit_obstacle(body):
	if body.name in ["Player", "Frog"]:
		trigger_game_over()
		
func trigger_game_over():
	if game_over:
		return
	print("💀 GAME OVER!")
	game_over = true
	game_started = false
	if player:
		if player.has_method("set_can_move"):
			player.set_can_move(false)
		player.velocity = Vector2.ZERO
	check_high_score()
	await get_tree().create_timer(0.5).timeout
	show_game_over_screen()

func hit_enemy(body, enemy):
	if body.name in ["Player", "Frog"]:
		points += 1000
		show_points()
		remove_enemy(enemy)

func adjust_difficulty():
	if score < 500:
		difficulty = 0
	elif score < 1500:
		difficulty = 1
	else:
		difficulty = 2

func setup_starting_positions():
	if player:
		player.global_position = player_start_pos
		player.velocity = Vector2.ZERO
		if player.has_method("set_can_move"):
			player.set_can_move(true)
	if camera:
		camera.global_position = camera_start_pos
		if camera.has_method("reset_position"):
			camera.reset_position()

func show_start_screen():
	print("=== RIBBIT RUSH ===")
	game_started = false

func start_game():
	if game_over:
		return
	game_started = true
	game_over = false
	score = 0
	points = 0
	difficulty = 0
	speed = START_SPEED
	last_obs_x = 0
	show_score()
	show_points()
	hide_game_name()
	hide_start_game()
	if game_over_ui:
		game_over_ui.visible = false
	for obs in obstacles:
		if is_instance_valid(obs): obs.queue_free()
	obstacles.clear()
	for enemy in enemies:
		if is_instance_valid(enemy): enemy.queue_free()
	enemies.clear()
	if player and player.has_method("set_can_move"):
		player.set_can_move(true)

func show_game_over_screen():
	if game_over_ui:
		update_game_over_labels()
		game_over_ui.visible = true
		if restart_button:
			restart_button.grab_focus()

func restart_game():
	print("🔁 Restarting...")
	game_over = false
	game_started = false
	score = 0
	points = 0
	distance_traveled = 0.0
	difficulty = 0
	speed = START_SPEED
	last_obs_x = 0
	show_points()
	show_score()
	if game_over_ui:
		game_over_ui.visible = false
	for obs in obstacles:
		if is_instance_valid(obs): obs.queue_free()
	obstacles.clear()
	for enemy in enemies:
		if is_instance_valid(enemy): enemy.queue_free()
	enemies.clear()
	setup_starting_positions()
	start_game()

func _on_restart_button_pressed():
	restart_game()

func show_score():
	if has_node("HUD") and $HUD.has_node("ScoreLabel"):
		$HUD.get_node("ScoreLabel").text = "SCORE: " + str(int(score))

func show_points():
	if has_node("HUD") and $HUD.has_node("PointLabel"):
		$HUD.get_node("PointLabel").text = "GOBBLE METER: " + str(int(points))

func hide_game_name():
	if has_node("HUD") and $HUD.has_node("GameName"):
		$HUD.get_node("GameName").hide()

func hide_start_game():
	if has_node("HUD") and $HUD.has_node("StartGame"):
		$HUD.get_node("StartGame").hide()

func update_game_over_labels():
	if not game_over_ui:
		return
	var score_label = game_over_ui.find_child("*Score*", true, false)
	if score_label and score_label is Label:
		score_label.text = "FINAL SCORE: " + str(int(score))
	var points_label = game_over_ui.find_child("*Points*", true, false)
	if points_label and points_label is Label:
		points_label.text = "POINTS: " + str(int(points))
	var high_score_label = game_over_ui.find_child("*HighScore*", true, false)
	if high_score_label and high_score_label is Label:
		high_score_label.text = "HIGH SCORE: " + str(int(high_score / SCORE_MODIFIER))
