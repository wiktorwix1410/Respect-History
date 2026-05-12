extends Node2D

@onready var area: Area2D = $Area2D

@export var contents: Array[ItemData] = []
@export var coin_amount: int = 0
var is_open: bool = false
var player_body: Node2D = null


func _ready() -> void:
	add_to_group("chests")
	add_to_group("resettable")
	area.area_entered.connect(player_entered)

func player_entered(body: Node2D) -> void:
	#Check if chest was already opened
	if is_open:
		return
	#Makes sure the colliding object is the player character
	var player: Node2D = body.get_parent() if body is Area2D else body
	
	if player.is_in_group("player"):
		player_body = player
		print("Chest opened")
		open_chest()
		
func open_chest() -> void:
	is_open = true
	if contents.size() > 0:
		player_body.on_items_received(contents)
		contents = [] 
	if coin_amount > 0:
		player_body.add_coins(coin_amount)
		coin_amount = 0
		
func save_data() -> Dictionary:
	return {
		"is_open": is_open,
		"contents": contents.duplicate(),
		"coin_amount": coin_amount
	}

func load_save_data(data: Dictionary) -> void:
	is_open = data["is_open"]
	contents = data["contents"]
	coin_amount = data["coin_amount"]
