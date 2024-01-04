extends Control

const MAX_HP = 20
const MAX_STAMINA = 5
const MAX_SP = 100

@onready var player = $Player as Wrestler
@onready var opponent = %Opponent as Wrestler
@onready var active_wrestler = player as Wrestler

const CARD = preload("res://src/card.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	player.opponent = opponent
	opponent.opponent = player
	
	player.setup_wrestler(WrestlerDatabase.get_wrestler_by_name("Player"))
	opponent.setup_wrestler(WrestlerDatabase.get_wrestler_by_name("Guy"))
	
	var player_data = WrestlerDatabase.get_player() as WrestlerData
	for card_name in player_data.attack_list:
		var data = CardDatabase.get_card_by_name(card_name)
		var card = CARD.instantiate() as Card
		card.populate_from_data(data)
		card.root = self
		%Cards.add_child(card)
	
	for direction_name in player_data.direction_list:
		var data = CardDatabase.get_card_by_name(direction_name)
		var card = CARD.instantiate() as Card
		card.populate_from_data(data)
		card.root = self
		%Directions.add_child(card)
	
	update_bars()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func update_bars():
	%PlayerHealthBar.value = player.hp
	%PlayerStaminaBar.value = player.stamina
	%PlayerSPBar.value = player.sp
	%OpponentHealthBar.value = opponent.hp
	%OpponentStaminaBar.value = opponent.stamina
	%OpponentSPBar.value = opponent.sp


func play_card(card: Card):
	var card_data = card.card_data
	if card_data.health_cost > active_wrestler.hp || card_data.stamina_cost > active_wrestler.stamina || card_data.sp_cost > active_wrestler.sp:
		return
	
	active_wrestler.hp -= card_data.health_cost
	active_wrestler.stamina -= card_data.stamina_cost
	active_wrestler.sp -= card_data.sp_cost
	update_bars()
	card.queue_free()
	
	%StatusText.text = active_wrestler.display_name + " uses " + card_data.display_name + "!"
	%StatusPopup.show()
	%TheBlocker.show()
	
	await get_tree().create_timer(1).timeout
	%StatusPopup.hide()
	%TheBlocker.hide()
	
	active_wrestler.opponent.hp -= card_data.damage
	active_wrestler.opponent.stamina -= card_data.stamina_damage
	update_bars()


func _on_play_card_pressed():
	%Cards.show()
	%Directions.hide()


func _on_direction_pressed():
	%Cards.hide()
	%Directions.show()


func _on_stance_up_pressed():
	%StatusText.text = player.display_name + " regains their stance."
	%StatusPopup.show()
	%TheBlocker.show()
	
	await get_tree().create_timer(1).timeout
	%StatusPopup.hide()
	%TheBlocker.hide()
	
	active_wrestler.stamina = MAX_STAMINA
	update_bars()
