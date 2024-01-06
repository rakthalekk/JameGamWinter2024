extends Control

@export var shop_items : Array[Item]

var CARDBUTTON = preload("res://src/card_shop_button.tscn")

var selected_card: CardShopButton

# Called when the node enters the scene tree for the first time.
func _ready():
	for item in shop_items:
		var data = CardDatabase.get_card_by_name(item.item_name)
		var card = CARDBUTTON.instantiate() as CardShopButton
		card.populate_from_data(data, item.cost)
		card.root = self
		%Cards.add_child(card)
	
	%Fame.text = str(Global.fame) + " Fame"


func card_click(card: CardShopButton):
	%CardInfo.text = card.card_data.display_name
	selected_card = card


func _on_buy_pressed():
	if selected_card:
		if Global.fame >= selected_card.card_cost:
			Global.fame -= selected_card.card_cost
			Global.player_card_list.append(selected_card.card_data)
			%Fame.text = str(Global.fame) + " Fame"
			selected_card.queue_free()
			selected_card = null
			%CardInfo.text = "No Card Selected"
		else:
			%CardInfo.text += "\nSorry Bud you cant afford that"


func _on_leave_pressed():
	get_tree().change_scene_to_file("res://src/main.tscn")
