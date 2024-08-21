extends TextureButton


func _on_button_down():
	for button in get_parent().get_children():
		button.get_node("ButtonAnimator").play("idle")
	
	$ButtonAnimator.play("pressed")
	$ClickSound.play()


func _on_mouse_entered():
	if $Sprite2D.frame != 1:
		$ButtonAnimator.play("hover")
		$HoverSound.pitch_scale = randf_range(0.95, 1.05)
		$HoverSound.play()


func _on_focus_entered() -> void:
	_on_button_down()
