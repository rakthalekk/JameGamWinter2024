extends Control


func _ready():
	if Global.game_opened:
		$AnimationPlayer.play("fade_in")
		await $AnimationPlayer.animation_finished


func _on_button_pressed():
	$AnimationPlayer.play("fade")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://src/main.tscn")
