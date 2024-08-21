class_name CardSelectionButton
extends Control

var root

var in_deck = false

var card_data: CardData

@onready var button = $Button as Button

func populate_from_data(data: CardData):
	card_data = data
	
	name = card_data.name
	%Name.text = data.display_name.to_lower()
	
	%Damage.text = "%02d" % card_data.damage
	
	$Sprite.texture = data.texture
	
	if data.type == CardData.CARDTYPE.DIRECTION:
		%Damage.text = str(data.sp_cost) + "% sp"
	elif data.type == CardData.CARDTYPE.UTILITY:
		%Damage.text = ""


func _on_button_pressed():
	if in_deck:
		root.remove_from_deck(self)
	else:
		root.add_to_deck(self)


func _on_button_mouse_entered():
	root.update_tooltip(self)


func _on_button_focus_entered() -> void:
	$Highlight.show()
	root.update_tooltip(self)


func _on_button_focus_exited() -> void:
	$Highlight.hide()
