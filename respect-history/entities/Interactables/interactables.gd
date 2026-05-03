extends Node2D

@export var player: Node2D
@export var correct_password: String 
# TODO ^^^ rethink this (and password_ui) because other objects than computers wont need it
@onready var password_ui: Control = $Control
@onready var area: Area2D = $Area2D
@onready var icon: Sprite2D = $Icon

var is_in_range: bool = false
var is_menu_open: bool = false

func _ready():
	area.area_entered.connect(_on_entered)
	area.area_exited.connect(_on_exited)
	password_ui.close()
	icon.visible = false

func _process(delta: float):
	if is_in_range:
		if is_menu_open:

			if Input.is_action_just_released("cancel"):
				password_ui.close()
				player.is_dead = false
				is_menu_open = false
	
		if Input.is_action_just_released("interact"):
			interact_computer()
			
func _on_entered(body): # WARNING body is not used but without it the collision is undetected
	icon.visible = true
	is_in_range = true
			
func _on_exited(body):
	icon.visible = false
	is_in_range = false
	
func interact_computer():
	password_ui.open(correct_password)
	is_menu_open = true
	player.is_dead = true # WARNING used to block controls, not the best way to do it?

# TODO add riddle option for computers (look into password_input.gd)
# TODO add other functions for other objects
	
