extends AnimatedSprite2D

var last_horizontal_direction: String = "right"

func _ready() -> void:
	get_parent().moving.connect(animate_movement)
	get_parent().dead.connect(animate_death)

func animate_movement(direction: Vector2, is_moving: bool) -> void:	
	var dir_string: String = direction_to_string(direction)
	if dir_string == "left" or dir_string == "right":
		last_horizontal_direction = dir_string
	
	var animation_name: String

	if is_moving:
		if dir_string == "":
			return
		animation_name = "walk_" + dir_string
	else:
		animation_name = "idle_" + last_horizontal_direction
		
	play(animation_name)

func animate_death() -> void:
	play("dead")

func direction_to_string(dir: Vector2) -> String:
	match dir:
		Vector2.UP:
			return "up"
		Vector2.DOWN:
			return "down"
		Vector2.LEFT:
			return "left"
		Vector2.RIGHT:
			return "right"
	return ""
