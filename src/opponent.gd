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
	if sp == 100:
		action = try_pick_direction()
	
	# If the opponent has at least 4 stamina or a coin flip succeeds, and a direction has not been selected, attempt to attack
	if action == null && (stamina >= 4 || randf() < 0.5):
		action = try_pick_attack()
	
	if action != null:
		await root.play_card(action)
		choose_action()
	elif stamina == 0 || stamina <= 2 && randf() > 0.5:
		root.stance_up()
	else:
		root.banter("Hey I'm Walking over here!!!")


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
