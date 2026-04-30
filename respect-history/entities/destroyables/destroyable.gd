extends Node2D

@onready var area: Area2D = $Area2D

func _ready() -> void:
	area.area_entered.connect(player_entered)


func player_entered(_val) -> void:
	queue_free()
