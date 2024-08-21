class_name BanterCard
extends Control

var root

@onready var button = $Button as Button

func _ready():
	var card_data =  CardDatabase.get_card_by_name(name)
	$Sprite.texture = card_data.texture
	%Name.text = card_data.display_name.to_lower()
	
	$Tooltip.hide()
	%TooltipText.text = card_data.description + "\nEnds your turn"


func _on_button_pressed():
	$Button.release_focus()
	
	if name == "Stance Up":
		root._on_stance_up_pressed()
	elif name == "Crowd Pleaser":
		root._on_banter_button_pressed()
	elif name == "Crowd Loser":
		root._on_banter_button_2_pressed()
	elif name == "The Punshisher":
		root._on_banter_button_3_pressed()
	elif name == "The Kickisher":
		root._on_banter_button_4_pressed()


func _on_button_mouse_entered():
	$AnimationPlayer.play("go_up")
	$AudioStreamPlayer2D.volume_db = randf_range(5, 6)
	$AudioStreamPlayer2D.pitch_scale = randf_range(0.9, 1.06)
	$AudioStreamPlayer2D.stream = load("res://assets/Audio/Card/card hover.ogg")
	$AudioStreamPlayer2D.play()
	$Tooltip.show()


func _on_button_mouse_exited():
	$AnimationPlayer.play("go_down")
	$Tooltip.hide()
