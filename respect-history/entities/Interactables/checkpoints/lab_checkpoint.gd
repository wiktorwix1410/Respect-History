# Handles player checkpoints, player returning to checkpoint and objects returning to their saved state.
# Requires objects intended for reset to be in the "resettable" group
extends Node2D

@onready var area: Area2D = $Area2D

var is_activated: bool = false                #If the specific checkpoint is active
var was_active_before: bool = false           #If the specific checkpoint has been active before
var player_body: Node2D = null                #Reference for the player character


var world_snapshot: Array = []                #"Snapshot" of the world/resettables state

func _ready() -> void:
	add_to_group("checkpoints")               #Register this node in group so other nodes can find it
	
	#Connects to player_entered function if the player character enters the checkpoint
	area.area_entered.connect(player_entered)   
	
func player_entered(body: Node2D) -> void:
	
	#Check if checkpoint was already used or is used currently
	if was_active_before or is_activated:
		return
		
	#Makes sure the colliding object is the player character
	var player: Node2D = body.get_parent() if body is Area2D else body
	if player.is_in_group("player"):
		
		#Deactivate every checkpoint and activate this one, so that there are no multiple active checkpoints
		get_tree().call_group("checkpoints", "deactivate")
		is_activated = true
		player_body = player
		
		#Take the snapshot when the checkpoint is hit
		save_world_state()
		print("Checkpoint activated")
		if not player_body.checkp.is_connected(return_to_checkpoint):
			player_body.checkp.connect(return_to_checkpoint)

func deactivate() -> void:
	if is_activated:
		is_activated = false
		was_active_before = true
		world_snapshot.clear() # Free up memory as this checkpoint is now overwritten

#Saves the state of every object in the "resettable" group
func save_world_state() -> void:
	world_snapshot.clear()
	var targets = get_tree().get_nodes_in_group("resettable")
	
	for node in targets:
		# We can only "respawn" objects that have a saved .tscn file
		if node.scene_file_path != "":
			#Object data which is saved
			var data = {
				"scene": node.scene_file_path,
				"parent": node.get_parent(),
				"position": node.global_position,
				"name": node.name
			}
			#Adds the object's data into the array
			world_snapshot.append(data) 


func return_to_checkpoint() -> void:
	if is_activated and player_body:
		#1. Restores the player to the checkpoint
		player_body.moving.emit(Vector2.DOWN, false)    #Sets the player animation to "idle_down" for visual clarity
		player_body.global_position = global_position
		
		#2. Delete all current resettable objects
		var current_objects = get_tree().get_nodes_in_group("resettable")
		for node in current_objects:
			node.queue_free()
		
		#3. Rebuild objects from the snapshot
		for data in world_snapshot:
			var scene = load(data["scene"])
			var instance = scene.instantiate()
			
			# Put it back where it was
			data["parent"].add_child(instance)
			instance.global_position = data["position"]
			instance.name = data["name"]
			
			#Re-add to the group so it can be saved/reset again
			instance.add_to_group("resettable")
