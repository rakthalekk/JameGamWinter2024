extends Node

var player_card_list : Array[String]
var player_deck : Array[String]

var shop_items = ["Cross", "Gut Punch", "Low Blow", "Flying Kick", "Roundhouse Kick", "Crane Kick",  "Chokehold",
		"Full Nelson", "Suplex", "Back Breaker", "Piledriver", "Crowd Pleaser", "Crowd Loser", "The Punshisher", "The Kickisher"]

var fame: int = 0
var total_fame: int = 0
var battles_won: int = 0

var current_opponent = "Swan Divin Tyson"
var health_multiplier = 1
var damage_multiplier = 1

var game_opened = false

var non_mouse = true


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()


func get_next_opponent():
	if current_opponent == "Swan Divin Tyson":
		current_opponent = "The Big Cheese"
	elif current_opponent == "The Big Cheese":
		current_opponent = "Lunar Luchador"
	elif current_opponent == "Lunar Luchador":
		current_opponent = "Terry Thunder Thighs"
	elif current_opponent == "Terry Thunder Thighs":
		current_opponent = "Doc Chop"
	else:
		current_opponent = "Swan Divin Tyson"
		health_multiplier += 0.5
		damage_multiplier += 0.25


func reset_variables():
	shop_items = ["Cross", "Gut Punch", "Low Blow", "Flying Kick", "Roundhouse Kick", "Crane Kick",  "Chokehold",
		"Full Nelson", "Suplex", "Back Breaker", "Piledriver", "Crowd Pleaser", "Crowd Loser", "The Punshisher", "The Kickisher"]
	fame = 0
	total_fame = 0
	battles_won = 0
	current_opponent = "Swan Divin Tyson"
	health_multiplier = 1
	damage_multiplier = 1
	player_card_list.clear()
	player_deck.clear()
	WrestlerDatabase.initialize_data()
