class_name Wrestler
extends Sprite2D

var display_name : String

var max_hp := 20
var max_stamina := 5
var max_sp := 100

var hp = max_hp
var stamina = max_stamina
var sp = max_sp

var attack_list : Array[CardData]
var direction_list : Array[CardData]

var data: WrestlerData
var opponent: Wrestler

func setup_wrestler(wrestler_data: WrestlerData):
	data = wrestler_data
	texture = data.texture
	
	display_name = data.display_name
	max_hp = wrestler_data.max_hp
	hp = max_hp
	
	for attack in data.attack_list:
		attack_list.append(CardDatabase.get_card_by_name(attack))
	
	for direction in data.direction_list:
		direction_list.append(CardDatabase.get_card_by_name(direction))
