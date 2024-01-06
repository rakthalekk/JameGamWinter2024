class_name Opponent
extends Wrestler

# Method for determining the action that this opponent will take. This is the default strategy for an opponent;
# it may be overridden by specific enemy classes to change that enemy's strategy
func choose_action():
	root.check_game_end()
	if root.game_over:
		return
	
	var action: CardData = null
	
	# If the opponent has full SP, attempt to use a direction
	if (sp == 100 || sp >= 70 && randf() > 0.7) && !unpopular:
		action = try_pick_direction()
	
	# If the opponent has at least 4 stamina or a coin flip succeeds, and a direction has not been selected, attempt to attack
	if action == null && (stamina >= 4 || randf() < 0.5) && !stunned:
		action = try_pick_attack()
	
	if action != null:
		await root.play_card(action)
		choose_action()
	elif stamina == 0 || stamina <= 2 && randf() > 0.5:
		root.stance_up()
	else:
		var random = randf()
		if random < 0.2:
			root._on_banter_button_pressed()
		elif random < 0.4:
			root._on_banter_button_2_pressed()
		elif random < 0.6:
			root._on_banter_button_3_pressed()
		elif random < 0.8:
			root._on_banter_button_4_pressed()
		else:
			root._on_banter_button_5_pressed()


# Attempts to select an attack if one is available. May be overridden by specific enemies
func try_pick_attack() -> CardData:
	# Randomize hand and pick first one that succeeds
	hand.shuffle()
	for attack in hand:
		if attack.stamina_cost <= stamina && attack.health_cost <= hp:
			return attack
	
	return null


# Attempts to select an attack if one is available. May be overridden by specific enemies
func try_pick_direction() -> CardData:
	# Randomize attack list and pick first one that succeeds
	direction_list.shuffle()
	for direction in direction_list:
		if direction.sp_cost <= sp:
			return direction
	
	return null
