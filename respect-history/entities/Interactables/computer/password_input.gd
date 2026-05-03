extends Control

@onready var cells = $Panel/HBoxContainer.get_children()

var password: String = ""
var max_length: int = 4
var active: bool = false
var correct_password: String

func _input(event: InputEvent):
	if not active:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_BACKSPACE:
			if password.length() > 0:
				password = password.substr(0, password.length()-1)
		elif event.keycode == KEY_ENTER:
			check_password()
		elif event.unicode != 0 and password.length() < max_length:
			var character = char(event.unicode)
			if character.is_valid_int(): # WARNING allowing only the numbers input
				password += char(event.unicode)
	update_cells()

func open(passwd): # getting the correct password from Computer node
	correct_password = passwd
	visible = true
	active = true
	password = ""
	update_cells()

func close():
	visible = false
	active = false

func update_cells():
	for i in range(cells.size()):
		if i < password.length():
			cells[i].text = password[i]
		else:
			cells[i].text = ""

func check_password():
	if password == correct_password:
		print("correct")
		# TODO emit a signal to a door to open
		close()
		# WARNING initiating an action so to not refer to other objects too much
		Input.action_release("cancel")
	else:
		print("wrong")
		password = ""
		update_cells()
	
# TODO add riddle for computers
	
