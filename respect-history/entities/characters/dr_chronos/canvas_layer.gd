extends Node2D

@onready var coin_label: Label = $CanvasLayer/Control/UI_Background/HBoxContainer/CoinLabel
@onready var key_label: Label = $CanvasLayer/Control/UI_Background/HBoxContainer/KeyLabel

#Updates the coin text
func update_coin_display(amount: int) -> void:
	coin_label.text = str(amount)

#Updates the key text
func update_key_display(inventory: Array[ItemData]) -> void:
	var key_count: int = 0
	
	for item in inventory:
		if item.type == ItemData.ItemType.KEY:
			key_count += 1
			
	key_label.text = str(key_count)


func _on_dr__chronos_stats_changed(new_coins: int, new_inventory: Array[ItemData]) -> void:
	update_coin_display(new_coins)
	update_key_display(new_inventory)
