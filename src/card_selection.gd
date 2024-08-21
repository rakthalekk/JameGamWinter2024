extends Control

var CARDBUTTON = preload("res://src/card_selection_button.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	update_lists()
	
	if Global.non_mouse && %Deck.get_child_count() > 0:
		%Deck.get_child(0).get_child(0).button.grab_focus()


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
	
	update_card_focus_neighbors()


func update_card_focus_neighbors():
	var deck_count = 0
	for slot in %Deck.get_children():
		if slot.get_child_count() > 0:
			deck_count += 1
		else:
			break
	
	for i in range(deck_count):
		var card = %Deck.get_child(i).get_child(0) as CardSelectionButton
		
		if !card:
			continue
		
		card.button.focus_neighbor_bottom = card.button.get_path_to(%Cards.get_child(0).button)
		card.button.focus_neighbor_left = NodePath("")
		card.button.focus_neighbor_right = NodePath("")
		
		if i > 0:
			card.button.focus_neighbor_left = card.button.get_path_to(%Deck.get_child(i - 1).get_child(0).button)
		
		if i < deck_count - 1:
			card.button.focus_neighbor_right = card.button.get_path_to(%Deck.get_child(i + 1).get_child(0).button)
	
	for i in range(%Cards.get_child_count()):
		var card = %Cards.get_child(i) as CardSelectionButton
		
		if %Deck.get_child(0).get_child_count() > 0:
			card.button.focus_neighbor_top = card.button.get_path_to(%Deck.get_child(0).get_child(0).button)
		
		card.button.focus_neighbor_bottom = card.button.get_path_to($Finish)
		card.button.focus_neighbor_left = NodePath("")
		card.button.focus_neighbor_right = NodePath("")
		
		if i > 0:
			card.button.focus_neighbor_left = card.button.get_path_to(%Cards.get_child(i - 1).button)
		if i < %Cards.get_child_count() - 1:
			card.button.focus_neighbor_right = card.button.get_path_to(%Cards.get_child(i + 1).button)
	
	$Finish.focus_neighbor_top = $Finish.get_path_to(%Cards.get_child(0).button)


func remove_from_deck(card: CardSelectionButton):
	Global.player_deck.erase(card.card_data.name)
	
	var idx = 0
	for slot in %Deck.get_children():
		if slot.get_child_count() > 0:
			if slot.get_child(0) == card:
				break
			idx += 1
	
	update_lists()
	
	if idx == Global.player_deck.size() && idx > 0:
		idx -= 1
	
	if %Deck.get_child(idx).get_child_count() > 0:
		%Deck.get_child(idx).get_child(0).button.grab_focus()
	else:
		%Cards.get_child(0).button.grab_focus()
	
	card.in_deck = false


func add_to_deck(card: CardSelectionButton):
	if Global.player_deck.size() < 20:
		var index_of_card = Global.player_deck.find(card.card_data.name)
		if index_of_card != -1:
			Global.player_deck.insert(index_of_card, card.card_data.name)
		else:
			Global.player_deck.append(card.card_data.name)
		
		var idx = 0
		for card_card in %Cards.get_children():
			if card_card == card:
				break
			idx += 1
		
		update_lists()
		
		if idx == %Cards.get_child_count():
			idx -= 1
		
		%Cards.get_child(idx).button.grab_focus()
		
		card.in_deck = true


func update_tooltip(card: CardSelectionButton):
	%TooltipText.text = card.card_data.description
	
	if card.in_deck:
		if card.get_parent().get_parent().get_child(0).get_child(0) == card:
			%DeckScroll.scroll_horizontal = 0
		elif card.global_position.x < 0:
			%DeckScroll.scroll_horizontal -= 120
		elif card.global_position.x > 800:
			%DeckScroll.scroll_horizontal += 120
	else:
		if card.get_parent().get_child(0) == card:
			%CardScroll.scroll_horizontal = 0
		elif card.global_position.x < 0:
			%CardScroll.scroll_horizontal -= 120
		elif card.global_position.x > 800:
			%CardScroll.scroll_horizontal += 120


func _on_finish_pressed():
	$AnimationPlayer.play("fade_out")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://src/main.tscn")
