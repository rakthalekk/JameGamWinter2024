extends Node2D


func _ready():
	hide()


func get_player() -> WrestlerData:
	return $Player


func get_wrestler_by_name(wrestler_name: String) -> WrestlerData:
	return get_node(wrestler_name)
