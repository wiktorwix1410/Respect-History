extends Control

signal cancelled
signal open_door

@onready var cells = $Panel/HBoxContainer.get_children()
# WARNING these have to exacly in order as in the scene!!!
@onready var buttons = [
	$Panel/GridContainer/EnterButton,
	$Panel/GridContainer/Button0,
	$Panel/GridContainer/EraseButton,
	$Panel/GridContainer/Button1,
	$Panel/GridContainer/Button2,
	$Panel/GridContainer/Button3,
	$Panel/GridContainer/Button4,
	$Panel/GridContainer/Button5,
	$Panel/GridContainer/Button6,
	$Panel/GridContainer/Button7,
	$Panel/GridContainer/Button8,
	$Panel/GridContainer/Button9
]

var password: String = ""
var max_length: int = 4
var active: bool = false
var correct_password: String

var selected_index: int = 0
var columns: int = 3

func _ready():
	update_selection_visual()

func _process(delta: float):
	if not active:
		return
	# moving between cells
	if Input.is_action_just_released("move_down"):
		move_selection(0, 1)
	elif Input.is_action_just_released("move_up"):
		move_selection(0, -1)
	elif Input.is_action_just_released("move_left"):
		move_selection(-1, 0)
	elif Input.is_action_just_released("move_right"):
		move_selection(1, 0)
	elif Input.is_action_just_released("interact"):
		press_button()

func move_selection(dx: int, dy: int):
	var row = selected_index / columns
	var col = selected_index % columns

	col += dx
	row += dy
	row = clamp(row, 0, 3)
	col = clamp(col, 0, 2)
	var new_index = row * columns + col

	if new_index < buttons.size():
		selected_index = new_index

	update_selection_visual()


func update_selection_visual():
	for i in range(buttons.size()):
		if i == selected_index:
			buttons[i].modulate = Color.YELLOW
		else:
			buttons[i].modulate = Color.WHITE

func press_button():
	var button_name = buttons[selected_index].name
	match button_name:
		"EnterButton":
			check_password()
			return
		"EraseButton":
			password = ""
		_:
			if password.length() < max_length:
				password += buttons[selected_index].text
	update_cells()

func update_cells():
	for i in range(cells.size()):
		if i < password.length():
			cells[i].text = password[i]
		else:
			cells[i].text = ""

func check_password():
	if password == correct_password:
		print("correct")
		close()
		cancelled.emit()
		open_door.emit()
	else:
		print("wrong")
		password = ""
		update_cells()

func open(passwd): # getting the correct password from Computer node
	correct_password = passwd
	visible = true
	active = true
	
	password = ""
	selected_index = 0
	
	update_cells()
	update_selection_visual()

func close():
	visible = false
	active = false

# TODO add riddle for computers
	
