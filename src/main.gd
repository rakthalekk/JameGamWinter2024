extends Control

const MAX_STAMINA = 5
const MAX_SP = 100

var consecutive_punches = 0

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
		card.flip_over()
	
	update_bars()
	
	$AnimationPlayer.play("unobscure")
	%CardContainer.show()


func update_bars():
	%PlayerHealthBar.value = player.hp
	%PlayerStamina.frame = 5 - player.stamina
	%PlayerSPBar.value = player.sp
	%OpponentHealthBar.value = opponent.hp
	%OpponentStamina.frame = 5 - opponent.stamina
	%OpponentSPBar.value = opponent.sp


func play_card(card_data: CardData, card: Card = null):
	# Does nothing if the card cannot be afforded
	if card_data.health_cost >= active_wrestler.hp || card_data.stamina_cost > active_wrestler.stamina || card_data.sp_cost > active_wrestler.sp:
		return
	
	var is_direction = card_data.type == CardData.CARDTYPE.DIRECTION
	
	# Cannot perform direction if unpopular, cannot perform attack if stunned
	if is_direction && active_wrestler.unpopular || !is_direction && active_wrestler.stunned:
		return
	
	var flurry_punch = CardDatabase.get_card_by_name("Flurry of Blows")
	
	# Remove the card from the wrestler's hand and add it back to their deck if it isn't a direction
	if !is_direction:
		active_wrestler.hand.erase(card_data)
		
		# Flurry of Blows cannot exist in the deck
		if card_data != flurry_punch:
			active_wrestler.deck.append(card_data)
		
		# If a player plays an action card, destroy the card
		if card:
			card.queue_free()
	
	%StatusText.text = active_wrestler.display_name + " uses " + card_data.display_name + "!"
	await display_status_text()
	
	active_wrestler.hp -= card_data.health_cost
	active_wrestler.stamina -= card_data.stamina_cost
	active_wrestler.sp -= card_data.sp_cost
	
	if !active_wrestler.unpopular:
		# Grapples give 10% SP
		if card_data.type == CardData.CARDTYPE.GRAPPLE:
			active_wrestler.sp = min(MAX_SP, active_wrestler.sp + 10)
		elif card_data.type == CardData.CARDTYPE.PUNCH:
			if active_wrestler.punshisher:
				active_wrestler.sp = min(MAX_SP, active_wrestler.sp + 5)
			elif active_wrestler.kickicher:
				active_wrestler.sp = max(0, active_wrestler.sp - 5)
		elif card_data.type == CardData.CARDTYPE.KICK && active_wrestler.kickicher:
			if active_wrestler.kickicher:
				active_wrestler.sp = min(MAX_SP, active_wrestler.sp + 5)
			elif active_wrestler.punshisher:
				active_wrestler.sp = max(0, active_wrestler.sp - 5)
		elif card_data.type == CardData.CARDTYPE.FINISHER && active_wrestler.finisherer:
			active_wrestler.sp = min(MAX_SP, active_wrestler.sp + 20)
	
	var damage = calculate_damage(card_data)
	
	# Low Blow has a 50% chance to deal double damage and inflict unpopular
	var low_blow_flag = false
	if card_data.name == "Low Blow" && randf() < 0.5:
		damage *= 2
		low_blow_flag = true
	
	active_wrestler.opponent.hp = max(0, active_wrestler.opponent.hp - damage)
	
	if damage > 0 && active_wrestler.oversold:
		active_wrestler.oversold = false
	
	update_bars()
	
	# Additional effects for cards that can't be generalized to data
	await check_special_effects(card_data)
	
	if low_blow_flag:
		active_wrestler.opponent.unpopular = true
		await debuff_text(active_wrestler.opponent.display_name, "Unpopular")
	
	await check_debuff_rolls(card_data)
	
	await check_damage_reduction(card_data)
	
	update_bars()
	
	if card_data.type == CardData.CARDTYPE.PUNCH && card_data != flurry_punch:
		consecutive_punches += 1
		
		# Adds flurry punch to the wrestler's deck after using a punch
		if !active_wrestler.hand.has(flurry_punch):
			active_wrestler.hand.append(flurry_punch)
			if active_wrestler == player:
				var flurry_card = CARD.instantiate() as Card
				flurry_card.populate_from_data(flurry_punch)
				flurry_card.root = self
				%Cards.add_child(flurry_card)
				flurry_card.flip_over()
	else:
		clear_flurry_punch()
	
	recalculate_card_damage()
	check_game_end()


func clear_flurry_punch():
	consecutive_punches = 0
	var flurry_punch = CardDatabase.get_card_by_name("Flurry of Blows")
	if active_wrestler.hand.has(flurry_punch):
		active_wrestler.hand.erase(flurry_punch)
		
		for card in %Cards.get_children():
			if card.card_data == flurry_punch:
				card.queue_free()
				return


func recalculate_card_damage():
	for card in %Cards.get_children():
		card.update_damage(calculate_damage(card.card_data, player))


func calculate_damage(card_data: CardData, wrestler: Wrestler = active_wrestler) -> int:
	var damage = card_data.damage
	
	# Special conditions for punch moves
	if card_data.name == "Cross" && consecutive_punches > 0:
		damage += 2
	elif card_data.name == "Flurry of Blows":
		damage = 3 * (consecutive_punches - 1)
	
	# Oversold buff doubles damage dealt
	if damage > 0 && wrestler.oversold:
		damage *= 2
	
	# Reduces damage based on the opponent's resistance
	if card_data.type == CardData.CARDTYPE.PUNCH:
		damage *= (1 - wrestler.opponent.punch_damage_reduction)
		if wrestler.punshisher:
			damage *= 1.25
		elif wrestler.kickicher:
			damage *= 0.75
	elif card_data.type == CardData.CARDTYPE.KICK:
		damage *= (1 - wrestler.opponent.kick_damage_reduction)
		if wrestler.kickicher:
			damage *= 1.25
		elif wrestler.punshisher:
			damage *= 0.75
	elif card_data.type == CardData.CARDTYPE.FINISHER:
		damage *= (1 - wrestler.opponent.finisher_damage_reduction)
	
	# Applies damage multiplier of grapples when opponent is at low HP
	if card_data.low_health_damage_multiplier > 0 && wrestler.opponent.hp <= 50:
		damage *= card_data.low_health_damage_multiplier
	
	return damage


func check_special_effects(card_data: CardData):
	match card_data.name:
		"Oversell":
			active_wrestler.oversold = true
		"Second Wind":
			active_wrestler.hp = min(active_wrestler.max_hp, active_wrestler.hp + 25)
		"Throw the Match":
			active_wrestler.opponent.sp = max(0, active_wrestler.opponent.sp - 30)
		"Gutbuster":
			if active_wrestler.opponent.hp <= 50:
				active_wrestler.opponent.next_turn_stamina = false
				active_wrestler.opponent.stamina = max(0, active_wrestler.opponent.stamina - 2)
				await debuff_text(active_wrestler.opponent.display_name, "Stamina Debuff")
		"Body Slam":
			if active_wrestler.opponent.hp >= 50:
				active_wrestler.opponent.stunned = true
				await debuff_text(active_wrestler.opponent.display_name, "Stunned")


func check_debuff_rolls(card_data: CardData):
	if randi_range(0, 99) < card_data.stamina_debuff_chance:
		active_wrestler.opponent.next_turn_stamina = false
		active_wrestler.opponent.stamina = max(0, active_wrestler.opponent.stamina - 2)
		await debuff_text(active_wrestler.opponent.display_name, "Stamina Debuff")
	
	if randi_range(0, 99) < card_data.stunned_chance:
		active_wrestler.opponent.stunned = true
		await debuff_text(active_wrestler.opponent.display_name, "Stunned")
	
	if randi_range(0, 99) < card_data.unpopular_chance:
		active_wrestler.opponent.unpopular = true
		await debuff_text(active_wrestler.opponent.display_name, "Unpopular")


func check_damage_reduction(card_data: CardData):
	match card_data.name:
		"Arm Bar":
			active_wrestler.punch_damage_reduction = 0.5
			await damage_reduction_text(active_wrestler.display_name, "Punches")
		"Leg Lock":
			active_wrestler.kick_damage_reduction = 0.5
			await damage_reduction_text(active_wrestler.display_name, "Kicks")
		"Chokehold":
			active_wrestler.finisher_damage_reduction = 0.5
			await damage_reduction_text(active_wrestler.display_name, "Finishers")


func display_status_text(disable_blocker: bool = true, time: int = 1):
	%StatusPopup.show()
	%TheBlocker.show()
	
	await get_tree().create_timer(time).timeout
	%StatusPopup.hide()
	if disable_blocker && active_wrestler == player:
		%TheBlocker.hide()


func debuff_text(wrestler: String, debuff: String):
	%StatusText.text = wrestler + " is inflicted with " + debuff + "!"
	await display_status_text()


func damage_reduction_text(wrestler: String, type: String):
	%StatusText.text = wrestler + " is protected against " + type + "!"
	await display_status_text()


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
	clear_flurry_punch()
	
	active_wrestler.reset_penalties()
	
	if active_wrestler == player:
		active_wrestler = opponent
		$AnimationPlayer.play("obscure")
	else:
		active_wrestler = player
		_on_play_card_pressed()
		$AnimationPlayer.play("unobscure")
	
	active_wrestler.reset_defense_buffs()
	
	draw_new_hand()
	recalculate_card_damage()
	
	%StatusText.text = active_wrestler.display_name + " is ready to wrestle!"
	await display_status_text(false, 2)
	
	# Wrestler gains 1 stamina upon starting their turn
	if active_wrestler.next_turn_stamina:
		active_wrestler.stamina = min(MAX_STAMINA, active_wrestler.stamina + 1)
	
	# Wrestler gains 10 SP upon starting their turn
	if !active_wrestler.unpopular:
		active_wrestler.sp = min(MAX_SP, active_wrestler.sp + 10)
	
	update_bars()
	
	if active_wrestler == opponent:
		opponent_turn()
	else:
		%TheBlocker.hide()


func opponent_turn():
	opponent.choose_action()


func draw_new_hand():
	active_wrestler.get_random_hand()
	
	if active_wrestler == player:
		for i in range(%Cards.get_child_count(), 5):
			var card_data = player.hand[i]
			var card = CARD.instantiate() as Card
			card.populate_from_data(card_data)
			card.root = self
			%Cards.add_child(card)


func stance_up():
	active_wrestler.reset_attack_buffs()
	%StatusText.text = active_wrestler.display_name + " regains their stance."
	await display_status_text(false)
	
	active_wrestler.stamina = min(MAX_STAMINA, active_wrestler.stamina + 2)
	update_bars()
	change_turn()


func _on_play_card_pressed():
	%CardContainer.show()
	%DirectionContainer.hide()
	%BanterContainer.hide()


func _on_direction_pressed():
	%CardContainer.hide()
	%DirectionContainer.show()
	%BanterContainer.hide()


func _on_stance_up_pressed():
	stance_up()


func _on_banter_button_pressed():
	active_wrestler.reset_attack_buffs()
	%StatusText.text = active_wrestler.display_name + ": im a crowd pleaser!!!!"
	await display_status_text(false)
	
	if !active_wrestler.unpopular:
		active_wrestler.sp = min(MAX_SP, active_wrestler.sp + 30)
	else:
		%StatusText.text = "But the crowd did not respond..."
		await display_status_text(false)
	
	update_bars()
	change_turn()


func _on_banter_button_2_pressed():
	active_wrestler.reset_attack_buffs()
	%StatusText.text = active_wrestler.display_name + ": your a crowd loser!!!!"
	await display_status_text(false)
	
	active_wrestler.opponent.unpopular = true
	await debuff_text(active_wrestler.opponent.display_name, "Unpopular")
	
	update_bars()
	change_turn()


func _on_banter_button_3_pressed():
	active_wrestler.reset_attack_buffs()
	%StatusText.text = active_wrestler.display_name + ": its punshishering time!!!!"
	await display_status_text(false)
	
	active_wrestler.punshisher = true
	
	update_bars()
	change_turn()


func _on_banter_button_4_pressed():
	active_wrestler.reset_attack_buffs()
	%StatusText.text = active_wrestler.display_name + ": its kickishering time!!!!"
	await display_status_text(false)
	
	active_wrestler.kickicher = true
	
	update_bars()
	change_turn()


func _on_banter_pressed():
	%CardContainer.hide()
	%DirectionContainer.hide()
	%BanterContainer.show()


func _on_banter_button_5_pressed():
	active_wrestler.reset_attack_buffs()
	%StatusText.text = active_wrestler.display_name + ": its finishering time!!!!"
	await display_status_text(false)
	
	active_wrestler.finisherer = true
	
	update_bars()
	change_turn()


func flip_over_cards():
	for card in %Cards.get_children():
		card.flip_over()
		await get_tree().create_timer(.2).timeout
