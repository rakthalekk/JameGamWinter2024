class_name Card
extends Control

var root

var card_data: CardData
var effective_damage: int

func populate_from_data(data: CardData):
	card_data = data
	
	name = card_data.name
	%Name.text = data.display_name
	
	$Sprite.texture = data.texture
	
	effective_damage = data.damage
	%Damage.text = str(effective_damage) + " DMG"
	
	if data.type == CardData.CARDTYPE.DIRECTION:
		%Damage.hide()


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
	$AudioStreamPlayer2D.pitch_scale = randf_range(0.9, 1.06)
	$AudioStreamPlayer2D.stream = load("res://assets/Audio/Card/card hover.ogg")
	$AudioStreamPlayer2D.play()


func _on_button_mouse_exited():
	$AnimationPlayer.play("go_down")
