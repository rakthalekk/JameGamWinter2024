extends Control

const MAX_STAMINA = 5
const MAX_SP = 100

var consecutive_punches = 0

var game_over = false
var turns = 0

var player_max_sp = false
var opponent_max_sp = false

@onready var player = $Player as Wrestler
@onready var opponent = %Opponent as Opponent
@onready var active_wrestler: Wrestler

const CARD = preload("res://src/card.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.game_opened = true
	player.opponent = opponent
	opponent.opponent = player
	player.root = self
	opponent.root = self
	
	player.setup_wrestler(WrestlerDatabase.get_wrestler_by_name("Player"))
	opponent.setup_wrestler(WrestlerDatabase.get_wrestler_by_name(Global.current_opponent))
	#opponent.setup_wrestler(WrestlerDatabase.get_wrestler_by_name("Player2"))
	
	opponent.max_hp *= Global.health_multiplier
	opponent.hp = opponent.max_hp
	
	match opponent.name:
		"Doc Chop":
			$DocShadow.show()
			%OpponentName.texture = load("res://assets/DC_Nameplatel.png")
		"The Big Cheese":
			$CheeseShadow.show()
			%OpponentName.texture = load("res://assets/TBG-Nameplate.png")
		"Swan Divin Tyson":
			$TysonShadow.show()
			%OpponentName.texture = load("res://assets/SwanDivinTysonTitleCard.png")
		"Terry Thunder Thighs":
			$TerryShadow.show()
			%OpponentName.texture = load("res://assets/TTT-Nameplate.png")
		"Lunar Luchador":
			$LuchadorShadow.show();
			%OpponentName.texture = load("res://assets/LunarLuchadorTitleCard.png")
	
	%PlayerHealthBar.max_value = player.max_hp
	%OpponentHealthBar.max_value = opponent.max_hp
	
	update_bars()
	
	await $AnimationPlayer.animation_finished
	
	%AnnouncerDialogue.text = "Announcer: Today's challenger against [color=orange]The Champion[/color] is...!"
	await display_announcer_dialog(true, 2)
	
	%AnnouncerDialogue.text = "Announcer: [color=orange]" + opponent.display_name + "[/color]!"
	await display_announcer_dialog(true, 1.5)
	
	$AnimationPlayer.play("intro")
	
	await $AnimationPlayer.animation_finished
	
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
	
	## Add direction focus neightbors
	for i in range(5):
		var card = %Directions.get_child(i) as Card
		
		card.button.focus_neighbor_top = card.button.get_path_to($VBoxContainer/Deck/MarginContainer/BottomMenu/ActionContainer/ActionButtons/Attack)
		card.button.focus_neighbor_bottom = card.button.get_path_to($VBoxContainer/Deck/MarginContainer/BottomMenu/ActionContainer/ActionButtons/Banter)
		
		if i > 0:
			card.button.focus_neighbor_left = card.button.get_path_to(%Directions.get_child(i - 1).button)
		if i < 4:
			card.button.focus_neighbor_right = card.button.get_path_to(%Directions.get_child(i + 1).button)
	
	## Add banter focus neightbors
	for i in range(5):
		var card = %SmackTalk.get_child(i) as BanterCard
		card.root = self
		
		card.button.focus_neighbor_top = card.button.get_path_to($VBoxContainer/Deck/MarginContainer/BottomMenu/ActionContainer/ActionButtons/Direction)
		
		if i > 0:
			card.button.focus_neighbor_left = card.button.get_path_to(%SmackTalk.get_child(i - 1).button)
		if i < 4:
			card.button.focus_neighbor_right = card.button.get_path_to(%SmackTalk.get_child(i + 1).button)
	
	active_wrestler = opponent
	change_turn()


func update_bars():
	%PlayerHealthBar.value = player.hp
	%PlayerStamina.frame = 5 - player.stamina
	%PlayerSPBar.value = player.sp
	%OpponentHealthBar.value = opponent.hp
	%OpponentStamina.frame = 5 - opponent.stamina
	%OpponentSPBar.value = opponent.sp
	
	if player.sp == 100:
		if !player_max_sp:
			$CrowdCheer.play()
			player_max_sp = true
	else:
		player_max_sp = false
	
	if opponent.sp == 100:
		if !opponent_max_sp:
			$CrowdCheer.play()
			opponent_max_sp = true
	else:
		opponent_max_sp = false


func play_card(card_data: CardData, card: Card = null):
	# Does nothing if the card cannot be afforded
	if card_data.health_cost >= active_wrestler.hp || card_data.stamina_cost > active_wrestler.stamina || card_data.sp_cost > active_wrestler.sp:
		return
	
	var is_direction = card_data.type == CardData.CARDTYPE.DIRECTION
	var is_utility = card_data.type == CardData.CARDTYPE.UTILITY
	
	# Cannot perform direction if unpopular, cannot perform attack if stunned
	if is_direction && active_wrestler.unpopular || !is_direction && !is_utility && active_wrestler.stunned:
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
	else:
		if card:
			card.button.release_focus()
	
	# Utility cards are considered first, rest of function is ignored
	if card_data.type == CardData.CARDTYPE.UTILITY:
		if card_data.name == "Stance Up":
			await stance_up(true)
		elif card_data.name == "Crowd Pleaser":
			await crowd_pleaser(true)
		elif card_data.name == "Crowd Loser":
			await crowd_loser(true)
		elif card_data.name == "The Punshisher":
			await the_punshisher(true)
		elif card_data.name == "The Kickisher":
			await the_kickisher(true)
		
		update_card_focus_neighbors()
		
		if active_wrestler == player:
			if Global.non_mouse && %Cards.get_child_count() > 0:
				%Cards.get_children()[0].button.grab_focus()
			else:
				_on_direction_pressed()
		
		recalculate_card_damage()
		clear_flurry_punch()
		update_bars()
		return
	
	match card_data.type:
		CardData.CARDTYPE.PUNCH:
			$PunchSound.play()
		CardData.CARDTYPE.KICK:
			$KickSound.play()
		CardData.CARDTYPE.GRAPPLE:
			$GrappleSound.play()
		CardData.CARDTYPE.FINISHER:
			$FinisherSound.play()
	
	%AnnouncerDialogue.text = "Announcer: [color=orange]" + active_wrestler.display_name + "[/color] uses [color=blue]" + card_data.display_name + "[/color]!"
	await display_announcer_dialog(true, 1.5)
	
	active_wrestler.hp -= card_data.health_cost
	active_wrestler.stamina -= card_data.stamina_cost
	active_wrestler.sp -= card_data.sp_cost
	
	# Grapples give 10% SP
	if !active_wrestler.unpopular && card_data.type == CardData.CARDTYPE.GRAPPLE:
		active_wrestler.sp = min(MAX_SP, active_wrestler.sp + 10)
	
	var damage = calculate_damage(card_data)
	
	# Low Blow has a 50% chance to deal double damage and inflict unpopular
	var low_blow_flag = false
	if card_data.name == "Low Blow" && randf() < 0.5:
		damage *= 2
		low_blow_flag = true
	
	if active_wrestler == opponent:
		damage *= Global.damage_multiplier
	
	active_wrestler.opponent.hp = max(0, active_wrestler.opponent.hp - damage)
	
	if damage > 0 && active_wrestler.oversold:
		active_wrestler.oversold = false
	
	update_bars()
	
	if damage > 0:
		$DamageSound.play()
		await $DamageSound.finished
	
	# Additional effects for cards that can't be generalized to data
	await check_special_effects(card_data)
	
	if low_blow_flag:
		active_wrestler.opponent.unpopular = true
		if active_wrestler.opponent == player:
			%PlayerUnpopularDebuff.show()
		else:
			%OpponentUnpopularDebuff.show()
		$DebuffSound.play()
		$CrowdBoo.play()
		await debuff_text(active_wrestler.opponent.display_name, "Unpopular")
	
	await check_debuff_rolls(card_data)
	
	await check_damage_reduction(card_data)
	
	update_bars()
	
	if card_data.type == CardData.CARDTYPE.PUNCH && card_data != flurry_punch:
		consecutive_punches += 1
		
		# Adds flurry punch to the wrestler's deck after using two punches, if they have at least one other card
		if consecutive_punches > 1 && !active_wrestler.hand.has(flurry_punch) && active_wrestler.hand.size() > 0:
			active_wrestler.hand.append(flurry_punch)
			if active_wrestler == player:
				var flurry_card = CARD.instantiate() as Card
				flurry_card.populate_from_data(flurry_punch)
				flurry_card.root = self
				%Cards.add_child(flurry_card)
				flurry_card.flip_over()
	else:
		clear_flurry_punch()
	
	update_card_focus_neighbors()
	
	if !is_direction:
		if active_wrestler == player:
			if Global.non_mouse && %Cards.get_child_count() > 0:
				%Cards.get_children()[0].button.grab_focus()
			else:
				_on_direction_pressed()
	else:
		if Global.non_mouse && active_wrestler == player && %Directions.get_child_count() > 0:
			%Directions.get_children()[0].button.grab_focus()
	
	recalculate_card_damage()
	check_game_end()


func clear_flurry_punch():
	consecutive_punches = 0
	var flurry_punch = CardDatabase.get_card_by_name("Flurry of Blows")
	if active_wrestler.hand.has(flurry_punch):
		active_wrestler.hand.erase(flurry_punch)
		
		for card in %Cards.get_children():
			if card.card_data == flurry_punch:
				# If the last unused card is frenzy, open direction menu
				if card.button.has_focus():
					_on_direction_pressed()
				
				card.queue_free()
				return


func recalculate_card_damage():
	for card in %Cards.get_children():
		card.update_damage(calculate_damage(card.card_data, player))
	
	for card in %Directions.get_children():
		card.update_damage(0)


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
			damage *= 1.5
	elif card_data.type == CardData.CARDTYPE.KICK:
		damage *= (1 - wrestler.opponent.kick_damage_reduction)
		if wrestler.kickicher:
			damage *= 1.5
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
		"Revved Up":
			active_wrestler.stamina = 5
		"Game Plan":
			for card in active_wrestler.hand:
				if card.display_name != "Frenzy":
					active_wrestler.deck.append(card)
			
			active_wrestler.hand.clear()
			if active_wrestler == player:
				for card in %Cards.get_children():
					%Cards.remove_child(card)
					card.queue_free()
			await draw_new_hand()
			if active_wrestler == player:
				await flip_over_cards()
		"Back Breaker":
			if active_wrestler.opponent.hp <= 50:
				active_wrestler.opponent.next_turn_stamina = false
				active_wrestler.opponent.stamina = max(0, active_wrestler.opponent.stamina - 2)
				if active_wrestler.opponent == player:
					%PlayerStaminaDebuff.show()
				else:
					%OpponentStaminaDebuff.show()
				await debuff_text(active_wrestler.opponent.display_name, "Stamina Debuff")
		"Body Slam":
			if active_wrestler.opponent.hp >= 50:
				active_wrestler.opponent.stunned = true
				if active_wrestler.opponent == player:
					%PlayerStunnedDebuff.show()
				else:
					%OpponentStunnedDebuff.show()
				await debuff_text(active_wrestler.opponent.display_name, "Stunned")
		"Heart Stopper":
			if active_wrestler.opponent.hp <= 50:
				if randf() <= 0.66:
					active_wrestler.opponent.stunned = true
					if active_wrestler.opponent == player:
						%PlayerStunnedDebuff.show()
					else:
						%OpponentStunnedDebuff.show()
					await debuff_text(active_wrestler.opponent.display_name, "Stunned")
		"Cheddar Crush":
			if active_wrestler.opponent.hp >= 50:
				active_wrestler.opponent.stunned = true
				if active_wrestler.opponent == player:
					%PlayerStunnedDebuff.show()
				else:
					%OpponentStunnedDebuff.show()
				await debuff_text(active_wrestler.opponent.display_name, "Stunned")
		"Neck Breaker":
			if active_wrestler.opponent.hp <= 50:
				active_wrestler.opponent.next_turn_stamina = false
				active_wrestler.opponent.stamina = max(0, active_wrestler.opponent.stamina - 2)
				if active_wrestler.opponent == player:
					%PlayerStaminaDebuff.show()
				else:
					%OpponentStaminaDebuff.show()
				await debuff_text(active_wrestler.opponent.display_name, "Stamina Debuff")
		"Dive Bomb":
			if active_wrestler.opponent.hp <= 50:
				active_wrestler.opponent.next_turn_stamina = false
				active_wrestler.opponent.stamina = max(0, active_wrestler.opponent.stamina - 2)
				if active_wrestler.opponent == player:
					%PlayerStaminaDebuff.show()
				else:
					%OpponentStaminaDebuff.show()
				await debuff_text(active_wrestler.opponent.display_name, "Stamina Debuff")
				await play_card(CardDatabase.get_card_by_name("Free Arm Bar"))
				
				active_wrestler.unpopular = true
				if active_wrestler == player:
					%PlayerUnpopularDebuff.show()
				else:
					%OpponentUnpopularDebuff.show()
				$CrowdBoo.play()
				await debuff_text(active_wrestler.display_name, "Unpopular")


func check_debuff_rolls(card_data: CardData):
	if randi_range(0, 99) < card_data.stamina_debuff_chance:
		active_wrestler.opponent.next_turn_stamina = false
		active_wrestler.opponent.stamina = max(0, active_wrestler.opponent.stamina - 2)
		if active_wrestler.opponent == player:
			%PlayerStaminaDebuff.show()
		else:
			%OpponentStaminaDebuff.show()
		await debuff_text(active_wrestler.opponent.display_name, "Stamina Debuff")
	
	if randi_range(0, 99) < card_data.stunned_chance:
		active_wrestler.opponent.stunned = true
		if active_wrestler.opponent == player:
			%PlayerStunnedDebuff.show()
		else:
			%OpponentStunnedDebuff.show()
		await debuff_text(active_wrestler.opponent.display_name, "Stunned")
	
	if randi_range(0, 99) < card_data.unpopular_chance:
		active_wrestler.opponent.unpopular = true
		if active_wrestler.opponent == player:
			%PlayerUnpopularDebuff.show()
		else:
			%OpponentUnpopularDebuff.show()
		$CrowdBoo.play()
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


func display_player_dialog(disable_blocker: bool = false):
	%PlayerDialogue.text = "[center]" + %PlayerDialogue.text
	$PlayerSpeechBubble.show()
	%TheBlocker.show()
	
	await get_tree().create_timer(2).timeout
	$PlayerSpeechBubble.hide()
	if disable_blocker:
		%TheBlocker.hide()


func display_opponent_dialog():
	%OpponentDialogue.text = "[center]" + %OpponentDialogue.text
	$OpponentSpeechBubble.show()
	%TheBlocker.show()
	
	await get_tree().create_timer(2).timeout
	$OpponentSpeechBubble.hide()


func display_announcer_dialog(disable_blocker: bool = true, time: float = 2):
	%AnnouncerDialogue.text = "[center]" + %AnnouncerDialogue.text
	$AnnouncerSpeechBubble.show()
	%TheBlocker.show()
	
	await get_tree().create_timer(time).timeout
	$AnnouncerSpeechBubble.hide()
	if disable_blocker && active_wrestler == player:
		%TheBlocker.hide()


func debuff_text(wrestler: String, debuff: String):
	%AnnouncerDialogue.text = "Announcer: [color=orange]" + wrestler + "[/color] is inflicted with [color=red]" + debuff + "[/color]!"
	$DebuffSound.play()
	match debuff:
		"Unpopular": 
				flicker_debuff_tooltip(%PlayerUPTooltip)
		"Stunned":
				flicker_debuff_tooltip(%PlayerSTNTooltip)
		"Stamina Debuff":	
				flicker_debuff_tooltip(%PlayerSDBTooltip)
	await display_announcer_dialog()

func flicker_debuff_tooltip(debuffTip):
	debuffTip.show()
	await get_tree().create_timer(2).timeout
	debuffTip.hide()


func damage_reduction_text(wrestler: String, type: String):
	%AnnouncerDialogue.text = "Announcer: [color=orange]" + wrestler + "[/color] is protected against " + type + "!"
	await display_announcer_dialog()


func check_game_end():
	var text = ""
	if player.hp <= 0:
		text = "The Champion has been defeated..."
	elif opponent.hp <= 0:
		text = opponent.display_name + " has been defeated!"
	
	if text != "":
		%Continue.grab_focus()
		%Continue.release_focus()
		
		$VBoxContainer/Deck/MarginContainer/BottomMenu/ActionContainer/ActionButtons/Attack.focus_mode = FocusMode.FOCUS_NONE
		$VBoxContainer/Deck/MarginContainer/BottomMenu/ActionContainer/ActionButtons/Direction.focus_mode = FocusMode.FOCUS_NONE
		$VBoxContainer/Deck/MarginContainer/BottomMenu/ActionContainer/ActionButtons/Banter.focus_mode = FocusMode.FOCUS_NONE
		
		game_over = true
		%TheBlocker.show()
		%AnnouncerDialogue.text = text
		await display_announcer_dialog(false, 2)
		
		$AnimationPlayer.play("results")
		
		if player.hp > 0:
			var fame1 = 200 + 2 * player.hp
			var factor = 0.75
			var term = "(Long Battle)"
			if turns <= 5:
				factor = 1.5
				term = "(Domination)"
			elif turns <= 10:
				factor = 1.25
				term = "(Quick Battle)"
			elif turns <= 15:
				factor = 1
				term = "(Average Battle)"
			var fame = floor(fame1 * factor)
			Global.fame += fame
			Global.total_fame += fame
			%Additive.text = "200 + 3 * %d HP = %d" % [player.hp, fame1]
			%Multiplicative.text = "%d * %.2f %s = %d" % [fame1, factor, term, fame]
			%TotalFame.text = "Total Fame Gained: %d" % fame
			%Continue.show()
			%Continue.grab_focus()
		else:
			%Additive.text = "You Lose!"
			%Multiplicative.text = "Matches Won: %d" % Global.battles_won
			%TotalFame.text = "Total Fame Gained: %d" % Global.total_fame
			%Continue2.show()
			%Continue2.grab_focus()


func change_turn():
	check_game_end()
	clear_flurry_punch()
	
	active_wrestler.reset_penalties()
	if active_wrestler == player:
		for icon in %PlayerDebuffIcons.get_children():
			icon.hide()
	else:
		for icon in %OpponentDebuffIcons.get_children():
			icon.hide()
	
	if active_wrestler == player:
		active_wrestler = opponent
		$AnimationPlayer.play("obscure")
	else:
		active_wrestler = player
		turns += 1
		%CardContainer.show()
		%DirectionContainer.hide()
		%BanterContainer.hide()
		$AnimationPlayer.play("unobscure")
	
	active_wrestler.reset_defense_buffs()
	
	draw_new_hand()
	
	%AnnouncerDialogue.text = "Announcer: [color=orange]" + active_wrestler.display_name + "[/color] is ready to wrestle!"
	await display_announcer_dialog(false, 2)
	
	$VBoxContainer/Deck/MarginContainer/BottomMenu/ActionContainer/ActionButtons/Attack/ButtonAnimator.play("pressed")
	$VBoxContainer/Deck/MarginContainer/BottomMenu/ActionContainer/ActionButtons/Banter/ButtonAnimator.play("idle")
	
	# Wrestler gains 1 stamina upon starting their turn
	if active_wrestler.next_turn_stamina:
		active_wrestler.stamina = min(MAX_STAMINA, active_wrestler.stamina + 1)
	
	# Wrestler gains 10 SP upon starting their turn
	if !active_wrestler.unpopular:
		active_wrestler.sp = min(MAX_SP, active_wrestler.sp + 10)
	
	update_bars()
	
	recalculate_card_damage()
	
	if active_wrestler == opponent:
		opponent_turn()
	else:
		%TheBlocker.hide()
		$VBoxContainer/Deck/MarginContainer/BottomMenu/ActionContainer/ActionButtons/Attack.grab_focus()


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
		
		update_card_focus_neighbors()


func update_card_focus_neighbors():
	for i in range(%Cards.get_child_count()):
		var card = %Cards.get_child(i) as Card
		
		card.button.focus_neighbor_bottom = card.button.get_path_to($VBoxContainer/Deck/MarginContainer/BottomMenu/ActionContainer/ActionButtons/Direction)
		card.button.focus_neighbor_left = NodePath("")
		card.button.focus_neighbor_right = NodePath("")
		
		if i > 0:
			card.button.focus_neighbor_left = card.button.get_path_to(%Cards.get_child(i - 1).button)
		if i < %Cards.get_child_count() - 1:
			card.button.focus_neighbor_right = card.button.get_path_to(%Cards.get_child(i + 1).button)


func stance_up(disable_blocker: bool = false):
	if active_wrestler == player:
		%PlayerDialogue.text = "[color=orange]" + active_wrestler.display_name + "[/color]: I'm regaining my stance!"
		await display_player_dialog(disable_blocker)
	else:
		%OpponentDialogue.text = "[color=orange]" + active_wrestler.display_name + "[/color]: I'm regaining my stance!"
		await display_opponent_dialog()
	
	active_wrestler.stamina = min(MAX_STAMINA, active_wrestler.stamina + 2)
	update_bars()


func crowd_pleaser(disable_blocker: bool = false):
	if active_wrestler == player:
		%PlayerDialogue.text = "[color=orange]" + active_wrestler.display_name + "[/color]: I'm gonna take you down!"
		await display_player_dialog(disable_blocker)
	else:
		%OpponentDialogue.text = "[color=orange]" + active_wrestler.display_name + "[/color]: I'm gonna take you down!"
		await display_opponent_dialog()
	
	if !active_wrestler.unpopular:
		active_wrestler.sp = min(MAX_SP, active_wrestler.sp + 30)
	else:
		%AnnouncerDialogue.text = "But the crowd did not respond..."
		await display_announcer_dialog(disable_blocker)
	
	update_bars()


func crowd_loser(disable_blocker: bool = false):
	if active_wrestler == player:
		%PlayerDialogue.text = "[color=orange]" + active_wrestler.display_name + "[/color]: You're nothing to me!"
		await display_player_dialog(disable_blocker)
	else:
		%OpponentDialogue.text = "[color=orange]" + active_wrestler.display_name + "[/color]: You're nothing to me!"
		await display_opponent_dialog()
	
	active_wrestler.opponent.unpopular = true
	if active_wrestler.opponent == player:
		%PlayerUnpopularDebuff.show()
	else:
		%OpponentUnpopularDebuff.show()
	$CrowdBoo.play()
	await debuff_text(active_wrestler.opponent.display_name, "Unpopular")
	
	update_bars()


func the_punshisher(disable_blocker: bool = false):
	if active_wrestler == player:
		%PlayerDialogue.text = "[color=orange]" + active_wrestler.display_name + "[/color]: I'm powering up my punches!"
		await display_player_dialog(disable_blocker)
	else:
		%OpponentDialogue.text = "[color=orange]" + active_wrestler.display_name + "[/color]: I'm powering up my punches!"
		await display_opponent_dialog()
	
	active_wrestler.punshisher = true
	
	update_bars()


func the_kickisher(disable_blocker: bool = false):
	if active_wrestler == player:
		%PlayerDialogue.text = "[color=orange]" + active_wrestler.display_name + "[/color]: I'm powering up my kicks!"
		await display_player_dialog(disable_blocker)
	else:
		%OpponentDialogue.text = "[color=orange]" + active_wrestler.display_name + "[/color]: I'm powering up my kicks!"
		await display_opponent_dialog()
	
	active_wrestler.kickicher = true
	
	update_bars()


func _on_play_card_pressed():
	%CardContainer.show()
	%DirectionContainer.hide()
	%BanterContainer.hide()
	
	if Global.non_mouse && %Cards.get_child_count() > 0:
		%Cards.get_children()[0].button.grab_focus()


func _on_direction_pressed():
	%CardContainer.hide()
	%DirectionContainer.show()
	%BanterContainer.hide()
	
	$VBoxContainer/Deck/MarginContainer/BottomMenu/ActionContainer/ActionButtons/Direction.grab_focus()
	
	if Global.non_mouse && %Directions.get_child_count() > 0:
		%Directions.get_children()[0].button.grab_focus()


func play_opponent_banter_sound():
	var num = randi_range(1, 4)
	if opponent.name == "Doc Chop":
		%OpponentAudio.stream = load("res://assets/Audio/Voice/doc chop-0" + str(num) + ".ogg")
	elif opponent.name == "The Big Cheese":
		%OpponentAudio.stream = load("res://assets/Audio/Voice/cheese-man-0" + str(num) + ".ogg")
	elif opponent.name == "Swan Divin Tyson":
		%OpponentAudio.stream = load("res://assets/Audio/Voice/tyson-0" + str(num) + ".ogg")
	elif opponent.name == "Lunar Luchador":
		%OpponentAudio.stream = load("res://assets/Audio/Voice/lunar luchador-0" + str(num) + ".ogg")
	else:
		%OpponentAudio.stream = load("res://assets/Audio/Voice/terry-good-0" + str(num) + ".ogg")
	
	%OpponentAudio.play()


func _on_stance_up_pressed():
	active_wrestler.reset_attack_buffs()
	if active_wrestler == opponent:
		play_opponent_banter_sound()
	await stance_up()
	change_turn()


func _on_banter_button_pressed():
	active_wrestler.reset_attack_buffs()
	if active_wrestler == opponent:
		play_opponent_banter_sound()
	await crowd_pleaser()
	change_turn()


func _on_banter_button_2_pressed():
	active_wrestler.reset_attack_buffs()
	if active_wrestler == opponent:
		play_opponent_banter_sound()
	await crowd_loser()
	change_turn()


func _on_banter_button_3_pressed():
	active_wrestler.reset_attack_buffs()
	if active_wrestler == opponent:
		play_opponent_banter_sound()
	await the_punshisher()
	change_turn()


func _on_banter_button_4_pressed():
	active_wrestler.reset_attack_buffs()
	if active_wrestler == opponent:
		play_opponent_banter_sound()
	await the_kickisher()
	change_turn()


func _on_banter_pressed():
	%CardContainer.hide()
	%DirectionContainer.hide()
	%BanterContainer.show()
	
	if Global.non_mouse && %SmackTalk.get_child_count() > 0:
		%SmackTalk.get_children()[0].button.grab_focus()


func flip_over_cards():
	for card in %Cards.get_children():
		card.flip_over()
		await get_tree().create_timer(.2).timeout


func _on_continue_pressed():
	Global.get_next_opponent()
	Global.battles_won += 1
	$AnimationPlayer.play("fade_out")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://src/card_shop.tscn")


func _on_continue_2_pressed():
	Global.reset_variables()
	$AnimationPlayer.play("fade_out")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://src/title_screen.tscn")
