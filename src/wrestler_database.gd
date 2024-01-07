extends Node2D


func _ready():
	hide()
	
	# Initializes global variables from player list of moves
	var player_data = get_player() as WrestlerData
	
	if Global.player_deck.is_empty():
		for card in player_data.attack_list:
			Global.player_deck.append(card)
			
			# The total number of cards that exist are added to the player's card list
			if !Global.player_card_list.has(card):
				var data = CardDatabase.get_card_by_name(card)
				for i in range(0, data.quantity):
					Global.player_card_list.append(card)


func get_player() -> WrestlerData:
	return $Player


func get_wrestler_by_name(wrestler_name: String) -> WrestlerData:
	return get_node(wrestler_name)
