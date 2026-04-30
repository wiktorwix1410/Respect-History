extends Node2D

@export_flags_2d_physics var wall_layer: int
@export_flags_2d_physics var entity_layer: int
@export_flags_2d_physics var destroyable_layer: int
@export_flags_2d_physics var player_layer: int

var _exclude_rids: Array[RID] = []

@export var fall_delay: float = 0.1
@export var slide_delay: float = 0.5 
var current_fall_time: float = 0.0
var current_slide_time: float = 0.0 

var falling: bool = false
var player_crushed: bool = false

@export var push_tiles_per_second: float = 2.0
@export var fall_tiles_per_second: float = 4.0 

var is_pushed: bool = false
var target_position: Vector2
var pending_slide_dir: int = 0

@export_group("Visuals")
@export var sprite: Node2D 
@export var shake_amplitude: float = 2.0
@export var shake_speed: float = 50.0
@export var slide_drift: float = 8.0 
var base_sprite_pos: Vector2

var push_speed: float:
	get:
		return Global.TILE_SIZE * push_tiles_per_second

var fall_speed: float:
	get:
		return Global.TILE_SIZE * fall_tiles_per_second

func _ready() -> void:
	target_position = global_position
	if sprite:
		base_sprite_pos = sprite.position
		
	_get_all_collision_rids(self)

func _get_all_collision_rids(node: Node) -> void:
	for child in node.get_children():
		if child is CollisionObject2D:
			_exclude_rids.append(child.get_rid())
		_get_all_collision_rids(child)

func _physics_process(delta: float) -> void:
	if is_pushed:
		global_position = global_position.move_toward(target_position, push_speed * delta)
		if global_position.distance_to(target_position) < 1:
			global_position = target_position
			is_pushed = false
		return 
		
	if falling:
		global_position = global_position.move_toward(target_position, fall_speed * delta)
		
		if global_position.distance_to(target_position) < 1:
			global_position = target_position
			check_player_crush(Vector2.ZERO) 
			
			var next_cell_solid: bool = check_cell(Vector2.DOWN, wall_layer) or check_cell(Vector2.DOWN, entity_layer) or check_cell(Vector2.DOWN, destroyable_layer)
			
			if not next_cell_solid:
				target_position = global_position + (Vector2.DOWN * Global.TILE_SIZE)
			else:
				falling = false
				Signals.movable_land.emit()
		return

	var has_wall_down: bool = check_cell(Vector2.DOWN, wall_layer)
	var has_entity_down: bool = check_cell(Vector2.DOWN, entity_layer)
	var has_destroyable_down: bool = check_cell(Vector2.DOWN, destroyable_layer)
	
	var solid_ground_below: bool = has_wall_down or has_entity_down or has_destroyable_down
	
	if solid_ground_below:
		current_fall_time = 0.0 
		
		if has_entity_down and not has_destroyable_down:
			var blocked_left: bool = (
				check_cell(Vector2.LEFT, wall_layer | entity_layer | player_layer | destroyable_layer) or 
				check_cell(Vector2(-1, 1), wall_layer | entity_layer | destroyable_layer) 
			)
			
			var blocked_right: bool = (
				check_cell(Vector2.RIGHT, wall_layer | entity_layer | player_layer | destroyable_layer) or 
				check_cell(Vector2(1, 1), wall_layer | entity_layer | destroyable_layer) 
			)
			
			var desired_slide_dir: int = 0
			if not blocked_left:
				desired_slide_dir = -1
			elif not blocked_right:
				desired_slide_dir = 1
				
			if desired_slide_dir != 0:
				if pending_slide_dir == desired_slide_dir:
					current_slide_time += delta
					if current_slide_time >= slide_delay:
						start_slide(desired_slide_dir) 
						current_slide_time = 0.0
						pending_slide_dir = 0
				else:
					pending_slide_dir = desired_slide_dir
					current_slide_time = 0.0
			else:
				pending_slide_dir = 0
				current_slide_time = 0.0
		else:
			pending_slide_dir = 0
			current_slide_time = 0.0
			
	else:
		pending_slide_dir = 0
		current_slide_time = 0.0 
		
		var has_player_down: bool = check_cell(Vector2.DOWN, player_layer)
		var target_delay: float = fall_delay * 5 if has_player_down else fall_delay
		
		current_fall_time += delta
		
		if current_fall_time >= target_delay:
			target_position = global_position + (Vector2.DOWN * Global.TILE_SIZE)
			falling = true
			current_fall_time = 0.0

	if sprite:
		if pending_slide_dir != 0 and current_slide_time > 0.0:
			var t: float = current_slide_time / slide_delay 
			var shake_offset: float = sin(current_slide_time * shake_speed) * shake_amplitude * t
			var drift_offset: float = pending_slide_dir * slide_drift * t
			
			sprite.position.x = base_sprite_pos.x + drift_offset + shake_offset
		else:
			sprite.position.x = base_sprite_pos.x 

func check_cell(dir_offset: Vector2, mask: int) -> bool:
	if mask == 0:
		return false
		
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	
	query.position = global_position + (dir_offset * Global.TILE_SIZE) + (dir_offset * 1.0)
	query.collision_mask = mask
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = _exclude_rids 
	
	var results: Array[Dictionary] = space_state.intersect_point(query)
	return results.size() > 0

func check_player_crush(dir_offset: Vector2) -> void:
	if player_crushed:
		return
	
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = global_position + (dir_offset * Global.TILE_SIZE) + (dir_offset * 1.0)
	query.collision_mask = player_layer
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = _exclude_rids
	
	var results: Array[Dictionary] = space_state.intersect_point(query)
	
	if results.size() > 0:
		var body: Node2D = results[0].collider
		if body:
			var player: Node2D = body.get_parent() if body is Area2D else body
			if player and player.is_in_group("player") and player.has_method("die"):
				player.die()
				player_crushed = true

func push(dir: int) -> bool:
	if falling or is_pushed:
		return false
		
	var dir_vector: Vector2 = Vector2.RIGHT if dir > 0 else Vector2.LEFT
	var mask_to_check: int = wall_layer | entity_layer | destroyable_layer
	
	var is_blocked: bool = check_cell(dir_vector, mask_to_check)
		
	if not is_blocked:
		target_position = global_position + (dir_vector * Global.TILE_SIZE)
		is_pushed = true 
		return true
		
	return false

func start_slide(dir: int) -> void:
	global_position.x += dir * Global.TILE_SIZE
	
	if sprite:
		sprite.position.x = base_sprite_pos.x
	
	target_position = global_position + (Vector2.DOWN * Global.TILE_SIZE)
	falling = true
	current_fall_time = 0.0
