extends Resource
class_name ItemData

#Allows to choose the type of item from a dropdown menu
enum ItemType { KEY }

@export var item_name: String = ""
@export var icon: Texture2D
@export var type: ItemType = ItemType.KEY # Default to KEY
