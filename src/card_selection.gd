extends Control

var CARDBUTTON = preload("res://src/card_selection_button.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	update_lists()


func update_lists():
	for card_slot in %Deck.get_children():
		for card in card_slot.get_children():
			card_slot.remove_child(card)
			card.queue_free()
	
	for card in %Cards.get_children():
		%Cards.remove_child(card)
		card.queue_free()
	
	var first_free_slot = 1
	var unequipped_cards = Global.player_card_list.duplicate()
	for card in Global.player_deck:
		var data = CardDatabase.get_card_by_name(card)
		var button = CARDBUTTON.instantiate() as CardSelectionButton
		button.populate_from_data(data)
		button.root = self
		button.in_deck = true
		%Deck.get_node("CardSlot" + str(first_free_slot)).add_child(button)
		first_free_slot += 1
		unequipped_cards.erase(card)
	
	%DeckNum.text = str(first_free_slot - 1) + "/20"
	
	for card in unequipped_cards:
		var data = CardDatabase.get_card_by_name(card)
		var button = CARDBUTTON.instantiate() as CardSelectionButton
		button.populate_from_data(data)
		button.root = self
		button.in_deck = false
		%Cards.add_child(button)


func remove_from_deck(card: CardSelectionButton):
	Global.player_deck.erase(card.card_data.name)
	
	update_lists()
	
	card.in_deck = false


func add_to_deck(card: CardSelectionButton):
	if Global.player_deck.size() < 20:
		var index_of_card = Global.player_deck.find(card.card_data.name)
		if index_of_card != -1:
			Global.player_deck.insert(index_of_card, card.card_data.name)
		else:
			Global.player_deck.append(card.card_data.name)
		
		update_lists()
		
		card.in_deck = true


func update_tooltip(card: CardSelectionButton):
	%TooltipText.text = card.card_data.description


func _on_finish_pressed():
	get_tree().change_scene_to_file("res://src/main.tscn")
