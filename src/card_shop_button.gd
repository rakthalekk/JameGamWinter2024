class_name CardShopButton
extends Control

var root

var card_data: CardData

func populate_from_data(data: CardData):
	card_data = data
	
	name = card_data.name
	%Name.text = data.display_name
	
	%Damage.text = str(card_data.damage) + " DMG"
	
	$Sprite.texture = data.texture
	
	if data.type == CardData.CARDTYPE.DIRECTION:
		%Damage.text = str(data.sp_cost) + "% sp"
	elif data.type == CardData.CARDTYPE.UTILITY:
		%Damage.text = ""


func _on_button_pressed():
	root.card_click(self)
