class_name Wrestler
extends Sprite2D

var root

var display_name : String

var max_hp := 20
var max_stamina := 5
var max_sp := 100

var hp = max_hp
var stamina = max_stamina
var sp = 0

var next_turn_stamina = true
var stunned = false
var unpopular = false

var oversold = false
var punch_damage_reduction = 0
var kick_damage_reduction = 0
var finisher_damage_reduction = 0

var punshisher = false
var kickicher = false
var finisherer = false

var attack_list : Array[CardData]
var direction_list : Array[CardData]

var hand : Array[CardData]
var deck : Array[CardData]

var data: WrestlerData
var opponent: Wrestler

func setup_wrestler(wrestler_data: WrestlerData):
	data = wrestler_data
	texture = data.texture
	name = data.name
	
	display_name = data.display_name
	max_hp = wrestler_data.max_hp
	hp = max_hp
	
	# temp way to add unlocked cards
	if name == "Player":
		for attack in Global.player_deck:
			var card = CardDatabase.get_card_by_name(attack)
			attack_list.append(card)
			deck.append(card)
	else:
		for attack in data.attack_list:
			var card = CardDatabase.get_card_by_name(attack)
			attack_list.append(card)
			deck.append(card)
	
	for direction in data.direction_list:
		direction_list.append(CardDatabase.get_card_by_name(direction))
	
	get_random_hand()


func reset_penalties():
	next_turn_stamina = true
	stunned = false
	unpopular = false


func reset_attack_buffs():
	punshisher = false
	kickicher = false
	finisherer = false


func reset_defense_buffs():
	punch_damage_reduction = 0
	kick_damage_reduction = 0
	finisher_damage_reduction = 0


func get_random_hand():
	deck.shuffle()
	
	while hand.size() < 5 && deck.size() > 0:
		var attack = deck[0]
		hand.append(attack)
		deck.erase(attack)
