extends Control


var instructions = ["Play as the champion of the Dunning Wrestler Group and defend your title against five challengers in this wrestling card game. Build a deck of powerful moves to use against your opponents, and wow the crowd with an engaging performance using stage directions. Leverage your fame to learn new moves from experienced wrestlers and try them out in the ring.

During the game, there are three meters to keep track of:
	[color=red]Health[/color]: Your total hit points, denoted by the top-left red bar. You and your opponent begin the match with 100 HP.
	[color=light_green]Stamina[/color]: Your Action points, denoted by the green bar, used to perform attacks. Wrestlers recover 1 stamina at the beginning of their turn, and can recover extra stamina by using the Stance Up or Revved Up cards.
	[color=light_blue]Stage Presence (SP)[/color]: Your special meter, denoted by the blue bar, used for special actions known as directions. Wrestlers recover 10% SP at the beginning of their turn, and by using grapples or the Hype Up action. ",
"On your turn, there are four types of actions to perform:

[color=brown]Attack[/color]: These are cards that will deal damage to the opponent. They cost stamina, indicated by the number of boxes on the card. The damage they deal is indicated by the number listed on the top bar of the card. New attack cards are drawn from your deck at the beginning of each turn. There are four types of attacks:
		[color=red]Punch[/color]: Low damage, low stamina cost moves. Using punch moves lets you unleash a Flurry, dealing more damage based on the number of consecutive punch cards.
		[color=light_blue]Kick[/color]: Medium/high damage, medium stamina cost moves.
		[color=light_green]Grapple[/color]: Low damage, medium stamina cost moves. These may inflict damage reduction to certain types of attacks, and they grant 10 SP after use.
		[color=orange]Finisher[/color]: High damage, high stamina cost moves. These do additional damage when the opponent is below 50% HP.",
"[color=gray]Direction[/color]: These cards will affect the game dramatically in some way. They cost stage presence, shown by the percentage at the top of the card. They are not a part of the player's deck, and can be used any time, so long as you have enough SP.
[color=purple]Banter[/color]: These cards will end your turn after use. Use it to get a small boost before the next turn, such as a stamina regeneration. Additionally, you can place a limited amount of banter cards into your deck for extra usages per turn.

That's all, good luck Champion!"]

var instructions_index = 0

func _ready():
	if Global.game_opened:
		$AnimationPlayer.play("fade_in")
		await $AnimationPlayer.animation_finished
	$Button.grab_focus()


func _on_button_pressed():
	$AnimationPlayer.play("fade")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://src/main.tscn")


func _on_how_to_play_pressed() -> void:
	update_text()
	$Instructions.show()
	$Instructions/ColorRect2/MarginContainer/NextText.grab_focus()
	
	$Button.focus_mode = FocusMode.FOCUS_NONE
	$HowToPlay.focus_mode = FocusMode.FOCUS_NONE
	$Quit.focus_mode = FocusMode.FOCUS_NONE


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_next_text_pressed() -> void:
	if instructions_index < instructions.size():
		instructions_index += 1
	
	update_text()


func _on_previous_text_pressed() -> void:
	if instructions_index > 0:
		instructions_index -= 1
	
	update_text()


func update_text():
	$Instructions/ColorRect2/MarginContainer/Close.hide()
	$Instructions/ColorRect2/MarginContainer/NextText.show()
	$Instructions/ColorRect2/MarginContainer/PreviousText.show()
	
	if instructions_index == instructions.size() - 1:
		$Instructions/ColorRect2/MarginContainer/NextText.hide()
		$Instructions/ColorRect2/MarginContainer/NextText.hide()
		$Instructions/ColorRect2/MarginContainer/Close.show()
		$Instructions/ColorRect2/MarginContainer/Close.grab_focus()
	
	if instructions_index == 0:
		$Instructions/ColorRect2/MarginContainer/PreviousText.hide()
		$Instructions/ColorRect2/MarginContainer/NextText.grab_focus()
	
	$Instructions/ColorRect2/MarginContainer/InstructionText.text = instructions[instructions_index]

func _on_close_pressed() -> void:
	$Instructions.hide()
	$Button.focus_mode = FocusMode.FOCUS_ALL
	$HowToPlay.focus_mode = FocusMode.FOCUS_ALL
	$Quit.focus_mode = FocusMode.FOCUS_ALL
	instructions_index = 0
	
	update_text()
	
	$HowToPlay.grab_focus()
