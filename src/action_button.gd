extends TextureButton


func _on_button_down():
	$ButtonAnimator.play("pressed")
	$ClickSound.play()


func _on_button_up():
	$ButtonAnimator.play("idle")


func _on_mouse_entered():
	$ButtonAnimator.play("hover")
