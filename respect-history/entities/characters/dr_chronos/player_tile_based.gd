extends Node2D

signal moving(dir: Vector2, is_moving: bool)
signal intro_complete
signal dead

@onready var ray_cast_up: RayCast2D = $Raycast/RayCastUp
@onready var ray_cast_down: RayCast2D = $Raycast/RayCastDown
@onready var ray_cast_left: RayCast2D = $Raycast/RayCastLeft
@onready var ray_cast_right: RayCast2D = $Raycast/RayCastRight

@export var target_camera: Camera2D

@export var tiles_per_second: float = 4.0
@export var push_tiles_per_second: float = 2.0

var is_pushing: bool = false

var move_speed: float:
	get:
		var current_tps: float = push_tiles_per_second if is_pushing else tiles_per_second
		return Global.TILE_SIZE * current_tps

var target_position: Vector2
var is_moving: bool = false
var current_direction: Vector2 = Vector2.ZERO

var last_emitted_dir: Vector2 = Vector2.ZERO
var last_emitted_moving: bool = false

var is_dead: bool = false

const TURN_DELAY: float = 0.05
var turn_delay_timer: float = 0.0

var intro_position: Vector2 # end position for player intro, currently tied to camera
var intro_complete_flag: bool = false # a flag primarily needed to unlock controls
var intro_started: bool = false # a flag needed to make a delay before intro starts
@export var intro_delay: float = 1.5

func _ready() -> void:
	add_to_group('player')

	target_position = global_position
	intro_position = target_camera.global_position
	
	await get_tree().create_timer(intro_delay).timeout
	intro_started = true

func _physics_process(delta: float) -> void:
	if turn_delay_timer > 0.0:
		turn_delay_timer -= delta
		return
	
	if not intro_complete_flag and intro_started:
		handle_intro_movement(delta)
	else:
		handle_input()
		move_to_target(delta)

func handle_intro_movement(delta: float):
	if global_position.distance_to(intro_position) <= 1:
		return
	
	target_position = intro_position
	is_moving = true
	current_direction = Vector2.RIGHT
	update_moving_signal(current_direction, true)
	
	global_position = global_position.move_toward(target_position, move_speed * delta)
	
	if global_position.distance_to(target_position) < 1:
		global_position = target_position
		is_moving = false
		intro_complete_flag = true
		intro_complete.emit()
		handle_input()

func handle_input() -> void:
	if is_moving or is_dead:
		return
	
	var direction: Vector2 = Vector2.ZERO
	
	if Input.is_action_pressed("move_up"):
		direction = Vector2.UP
	elif Input.is_action_pressed("move_down"):
		direction = Vector2.DOWN
	elif Input.is_action_pressed("move_left"):
		direction = Vector2.LEFT
	elif Input.is_action_pressed("move_right"):
		direction = Vector2.RIGHT
	
	move(direction)

func move(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		update_moving_signal(current_direction, false)
		return
	
	if direction != current_direction:
		current_direction = direction
		update_moving_signal(current_direction, false)
		turn_delay_timer = TURN_DELAY
		return
	
	if is_moving:
		return

	var can_move: bool = false
	var collider: Object = null
	
	match direction:
		Vector2.UP:
			ray_cast_up.force_raycast_update()
			can_move = not ray_cast_up.is_colliding()
			if not can_move: collider = ray_cast_up.get_collider()
		Vector2.DOWN:
			ray_cast_down.force_raycast_update()
			can_move = not ray_cast_down.is_colliding()
			if not can_move: collider = ray_cast_down.get_collider()
		Vector2.LEFT:
			ray_cast_left.force_raycast_update()
			can_move = not ray_cast_left.is_colliding()
			if not can_move: collider = ray_cast_left.get_collider()
		Vector2.RIGHT:
			ray_cast_right.force_raycast_update()
			can_move = not ray_cast_right.is_colliding()
			if not can_move: collider = ray_cast_right.get_collider()
	
	if not can_move and collider and (direction == Vector2.LEFT or direction == Vector2.RIGHT):
		var target_node: Object = collider
		if not target_node.has_method("push") and target_node.get_parent() and target_node.get_parent().has_method("push"):
			target_node = target_node.get_parent()
			
		if target_node.has_method("push"):
			if target_node.push(int(direction.x)):
				can_move = true
				is_pushing = true 
	
	if can_move:
		target_position = global_position + direction * Global.TILE_SIZE
		is_moving = true
		update_moving_signal(current_direction, true)
	else:
		update_moving_signal(current_direction, false)

func move_to_target(delta: float) -> void:
	if not is_moving:
		return
	
	global_position = global_position.move_toward(target_position, move_speed * delta)
	
	if global_position.distance_to(target_position) < 1:
		global_position = target_position
		is_moving = false
		is_pushing = false

func update_moving_signal(dir: Vector2, state: bool) -> void:
	if dir != last_emitted_dir or state != last_emitted_moving:
		moving.emit(dir, state)
		last_emitted_dir = dir
		last_emitted_moving = state

func die() -> void:
	is_dead = true
	print("dead")
	dead.emit()
