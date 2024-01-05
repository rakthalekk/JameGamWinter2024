class_name Card
extends Control

var root

var card_data: CardData
var effective_damage: int

func populate_from_data(data: CardData):
	card_data = data
	
	name = card_data.name
	%Name.text = data.display_name
	%Type.text = CardData.CARDTYPE.keys()[data.type]
	%Description.text = data.description
	
	effective_damage = data.damage
	%Damage.text = str(effective_damage) + " DMG"
	%HealthCost.text = str(data.health_cost) + " HP"
	%StaminaCost.text = str(data.stamina_cost) + " ST"
	%SPCost.text = str(data.sp_cost) + "% SP"
	
	if data.type == CardData.CARDTYPE.DIRECTION:
		%Damage.hide()
	if data.health_cost == 0:
		%HealthCost.hide()
	if data.stamina_cost == 0:
		%StaminaCost.hide()
	if data.sp_cost == 0:
		%SPCost.hide()


func update_damage(new_damage: int):
	effective_damage = new_damage
	if effective_damage > card_data.damage:
		%Damage.set("theme_override_colors/font_color", Color.FOREST_GREEN)
	elif effective_damage < card_data.damage:
		%Damage.set("theme_override_colors/font_color", Color.RED)
	else:
		%Damage.set("theme_override_colors/font_color", Color.BLACK)
	
	%Damage.text = str(effective_damage) + " DMG"


func _on_button_pressed():
	root.play_card(card_data, self)


func _on_button_mouse_entered():
	$AnimationPlayer.play("go_up")


func _on_button_mouse_exited():
	$AnimationPlayer.play("go_down")
