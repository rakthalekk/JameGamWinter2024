class_name Card
extends Control

var root

var card_data: CardData
var effective_damage: int

var been_flipped = false

func populate_from_data(data: CardData):
	card_data = data
	
	name = card_data.name
	%Name.text = data.display_name.to_lower()
	
	$Sprite.texture = data.texture
	
	effective_damage = data.damage
	%Damage.text = "%02d" % effective_damage
	
	if data.type == CardData.CARDTYPE.DIRECTION:
		%Damage.text = str(data.sp_cost) + "% sp"


func update_damage(new_damage: int):
	%Upvote.hide()
	%Downvote.hide()
	%x2.hide()
	
	effective_damage = new_damage
	if effective_damage > card_data.damage:
		%Upvote.show()
	elif effective_damage < card_data.damage:
		%Downvote.show()
	
	if root.player.oversold:
		%x2.show()
	
	%Damage.text = "%02d" % effective_damage


func flip_over():
	if !been_flipped:
		$AnimationPlayer.play("flip_over")
		been_flipped = true


func flip_back():
	$AnimationPlayer.play("flip_back")


func _on_button_pressed():
	root.play_card(card_data, self)


func _on_button_mouse_entered():
	$AnimationPlayer.play("go_up")
	$AudioStreamPlayer2D.pitch_scale = randf_range(0.9, 1.06)
	$AudioStreamPlayer2D.stream = load("res://assets/Audio/Card/card hover.ogg")
	$AudioStreamPlayer2D.play()


func _on_button_mouse_exited():
	$AnimationPlayer.play("go_down")


func play_flip_sound():
	$AudioStreamPlayer2D.pitch_scale = randf_range(0.9, 1.06)
	$AudioStreamPlayer2D.stream = load("res://assets/Audio/Card/card flip.ogg")
	$AudioStreamPlayer2D.play()
