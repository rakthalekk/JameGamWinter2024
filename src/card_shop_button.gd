class_name CardShopButton
extends ColorRect

var root

var card_data: CardData
var card_cost: int

func populate_from_data(data: CardData, cost: int):
	card_data = data
	card_cost = cost
	
	name = card_data.name
	%Name.text = data.display_name
	%Type.text = CardData.CARDTYPE.keys()[data.type]
	%Description.text = data.description
	%Damage.text = str(card_data.damage) + " DMG"
	%Cost.text = str(cost)
	
	if data.type == CardData.CARDTYPE.DIRECTION:
		%Damage.hide()


func _on_button_pressed():
	root.card_click(self)
