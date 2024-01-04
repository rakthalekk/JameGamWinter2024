extends Node2D


func get_card_by_name(card_name: String) -> CardData:
	return get_node(card_name)
