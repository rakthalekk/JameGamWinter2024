class_name Card
extends Control

var root

var card_data: CardData

func populate_from_data(data: CardData):
	card_data = data
	
	%Name.text = data.display_name
	%Type.text = CardData.CARDTYPE.keys()[data.type]
	%Description.text = data.description
	%Damage.text = str(data.damage) + " DMG"
	%HealthCost.text = str(data.health_cost) + " HP"
	%StaminaCost.text = str(data.stamina_cost) + " ST"
	%SPCost.text = str(data.sp_cost) + "% SP"
	
	if data.damage == 0:
		%Damage.hide()
	if data.health_cost == 0:
		%HealthCost.hide()
	if data.stamina_cost == 0:
		%StaminaCost.hide()
	if data.sp_cost == 0:
		%SPCost.hide()


func _on_button_pressed():
	root.play_card(card_data, self)


func _on_button_mouse_entered():
	$AnimationPlayer.play("go_up")


func _on_button_mouse_exited():
	$AnimationPlayer.play("go_down")
