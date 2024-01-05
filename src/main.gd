extends Control

const MAX_STAMINA = 5
const MAX_SP = 100

var game_over = false

@onready var player = $Player as Wrestler
@onready var opponent = %Opponent as Opponent
@onready var active_wrestler: Wrestler

const CARD = preload("res://src/card.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	player.opponent = opponent
	opponent.opponent = player
	player.root = self
	opponent.root = self
	active_wrestler = player
	
	player.setup_wrestler(WrestlerDatabase.get_wrestler_by_name("Player"))
	opponent.setup_wrestler(WrestlerDatabase.get_wrestler_by_name("Guy"))
	
	%PlayerHealthBar.max_value = player.max_hp
	%OpponentHealthBar.max_value = opponent.max_hp
	
	for card_data in player.hand:
		var card = CARD.instantiate() as Card
		card.populate_from_data(card_data)
		card.root = self
		%Cards.add_child(card)
	
	for direction_data in player.direction_list:
		var card = CARD.instantiate() as Card
		card.populate_from_data(direction_data)
		card.root = self
		%Directions.add_child(card)
	
	update_bars()


func update_bars():
	%PlayerHealthBar.value = player.hp
	%PlayerStamina.frame = 5 - player.stamina
	%PlayerSPBar.value = player.sp
	%OpponentHealthBar.value = opponent.hp
	%OpponentStamina.frame = 5 - opponent.stamina
	%OpponentSPBar.value = opponent.sp


func play_card(card_data: CardData, card: Card = null):
	# Does nothing if the card cannot be afforded
	if card_data.health_cost > active_wrestler.hp || card_data.stamina_cost > active_wrestler.stamina || card_data.sp_cost > active_wrestler.sp:
		return
	
	var is_direction = card_data.type == CardData.CARDTYPE.DIRECTION
	
	# Cannot perform direction if unpopular, cannot perform attack if stunned
	if is_direction && active_wrestler.unpopular || !is_direction && active_wrestler.stunned:
		return
	
	# Remove the card from the wrestler's hand and add it back to their deck if it isn't a direction
	if !is_direction:
		active_wrestler.hand.erase(card_data)
		active_wrestler.deck.append(card_data)
		
		# If a player plays an action card, destroy the card
		if card:
			card.queue_free()
	
	%StatusText.text = active_wrestler.display_name + " uses " + card_data.display_name + "!"
	%StatusPopup.show()
	if active_wrestler == player:
		%TheBlocker.show()
	
	await get_tree().create_timer(1).timeout
	%StatusPopup.hide()
	if active_wrestler == player:
		%TheBlocker.hide()
	
	active_wrestler.hp -= card_data.health_cost
	active_wrestler.stamina -= card_data.stamina_cost
	active_wrestler.sp -= card_data.sp_cost
	
	# Grapples give 10% SP
	if card_data.type == CardData.CARDTYPE.GRAPPLE:
		active_wrestler.sp = min(MAX_SP, active_wrestler.sp + 10)
	
	# Additional effects for cards that can't be generalized to data
	check_special_effects(card_data)
	
	var damage = card_data.damage
	if damage > 0 && active_wrestler.oversold:
		damage *= 2
		active_wrestler.oversold = false
	
	active_wrestler.opponent.hp = max(0, active_wrestler.opponent.hp - damage)
	
	update_bars()
	
	if randi_range(0, 99) < card_data.stamina_debuff_chance:
		active_wrestler.opponent.next_turn_stamina = false
		active_wrestler.opponent.stamina = max(0, active_wrestler.opponent.stamina - 2)
		await debuff_text(active_wrestler.opponent.display_name, "Stamina Debuff")
	
	if randi_range(0, 99) < card_data.stunned_chance:
		active_wrestler.opponent.stunned = true
		await debuff_text(active_wrestler.opponent.display_name, "Stunned")
	
	if randi_range(0, 99) < card_data.unpopular_chance:
		active_wrestler.unpopular = true
		await debuff_text(active_wrestler.opponent.display_name, "Unpopular")
	
	update_bars()
	
	check_game_end()


func check_special_effects(card_data: CardData):
	match card_data.display_name:
		"Oversell":
			active_wrestler.oversold = true


func debuff_text(wrestler: String, debuff: String):
	%StatusText.text = wrestler + " is inflicted with " + debuff + "!"
	%StatusPopup.show()
	%TheBlocker.show()
	
	await get_tree().create_timer(1).timeout
	%StatusPopup.hide()
	if active_wrestler == player:
		%TheBlocker.hide()


func check_game_end():
	var text = ""
	if player.hp <= 0:
		text = "The Champion has been defeated..."
	elif opponent.hp <= 0:
		text = opponent.display_name + " has been defeated!"
	
	if text != "":
		game_over = true
		%StatusText.text = text
		%StatusPopup.show()
		%TheBlocker.show()


func change_turn():
	check_game_end()
	
	if active_wrestler == player:
		active_wrestler = opponent
		player.reset_penalties()
		$AnimationPlayer.play("obscure")
	else:
		active_wrestler = player
		opponent.reset_penalties()
		_on_play_card_pressed()
		$AnimationPlayer.play("unobscure")
	
	draw_new_hand()
	
	%StatusText.text = active_wrestler.display_name + " is ready to wrestle!"
	%StatusPopup.show()
	%TheBlocker.show()
	
	await get_tree().create_timer(2).timeout
	%StatusPopup.hide()
	
	# Wrestler gains 1 stamina upon starting their turn
	if active_wrestler.next_turn_stamina:
		active_wrestler.stamina = min(MAX_STAMINA, active_wrestler.stamina + 1)
	
	# Wrestler gains 10 SP upon starting their turn
	if !active_wrestler.unpopular && active_wrestler.can_gain_sp:
		active_wrestler.sp = min(MAX_SP, active_wrestler.sp + 10)
	
	update_bars()
	
	if active_wrestler == opponent:
		for card in %Cards.get_children():
			card.queue_free()
		
		opponent_turn()
	else:
		%TheBlocker.hide()


func opponent_turn():
	opponent.choose_action()


func draw_new_hand():
	active_wrestler.get_random_hand()
	
	if active_wrestler == player:
		for card_data in player.hand:
			var card = CARD.instantiate() as Card
			card.populate_from_data(card_data)
			card.root = self
			%Cards.add_child(card)


func banter(text):
	%StatusText.text = active_wrestler.display_name + ": " + text
	%StatusPopup.show()
	%TheBlocker.show()
	
	await get_tree().create_timer(1).timeout
	%StatusPopup.hide()
	
	active_wrestler.sp = min(MAX_SP, active_wrestler.sp + 20)
	update_bars()
	change_turn()


func stance_up():
	%StatusText.text = active_wrestler.display_name + " regains their stance."
	%StatusPopup.show()
	%TheBlocker.show()
	
	await get_tree().create_timer(1).timeout
	%StatusPopup.hide()
	
	active_wrestler.stamina = min(MAX_STAMINA, active_wrestler.stamina + 2)
	update_bars()
	change_turn()


func _on_play_card_pressed():
	%Cards.show()
	%Directions.hide()
	%SmackTalk.hide()


func _on_direction_pressed():
	%Cards.hide()
	%Directions.show()
	%SmackTalk.hide()


func _on_stance_up_pressed():
	stance_up()


func _on_banter_button_pressed():
	%StatusText.text = active_wrestler.display_name + ": im a crowd pleaser!!!!"
	%StatusPopup.show()
	%TheBlocker.show()
	
	await get_tree().create_timer(1).timeout
	%StatusPopup.hide()
	
	active_wrestler.sp = min(MAX_SP, active_wrestler.sp + 30)
	update_bars()
	change_turn()


func _on_banter_button_2_pressed():
	%StatusText.text = active_wrestler.display_name + ": your a crowd loser!!!!"
	%StatusPopup.show()
	%TheBlocker.show()
	
	await get_tree().create_timer(1).timeout
	%StatusPopup.hide()
	
	active_wrestler.opponent.can_gain_sp = false
	if randf() > 0.5:
		active_wrestler.opponent.unpopular = true
		await debuff_text(active_wrestler.opponent.display_name, "Unpopular")
	
	update_bars()
	change_turn()


func _on_banter_button_3_pressed():
	banter(%BanterButton3.text)


func _on_banter_button_4_pressed():
	banter(%BanterButton4.text)


func _on_banter_pressed():
	%Cards.hide()
	%Directions.hide()
	%SmackTalk.show()
