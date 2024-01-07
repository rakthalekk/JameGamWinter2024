extends Control

var current_idx = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	show_card_info()
	
	%MyFame.text = str(Global.fame)


func show_card_info():
	if Global.shop_items.size() > 0:
		var item = CardDatabase.get_card_by_name(Global.shop_items[current_idx]) as CardData
		$CurrentCard.texture = item.texture
		%Damage.text = "%02d" % item.damage
		%Name.text = item.display_name.to_lower()
		%TooltipText.text = item.description
		$AnimationPlayer.play("flip_card")
		%FameCost.text = str(item.cost)


func _on_buy_pressed():
	var item = CardDatabase.get_card_by_name(Global.shop_items[current_idx]) as CardData
	if item.cost <= Global.fame:
		Global.fame -= item.cost
		%MyFame.text = str(Global.fame)
		
		# Append as many copies as exist of that card to the player's reserve
		for i in range(0, item.quantity):
			Global.player_card_list.append(item.name)

		Global.shop_items.remove_at(current_idx)
		
		if current_idx >= Global.shop_items.size():
			current_idx = 0
		show_card_info()


func _on_leave_pressed():
	get_tree().change_scene_to_file("res://src/main.tscn")


func _on_finish_pressed():
	get_tree().change_scene_to_file("res://src/card_selection.tscn")


func _on_left_pressed():
	current_idx -= 1
	if current_idx < 0:
		current_idx = Global.shop_items.size() - 1
	show_card_info()


func _on_right_pressed():
	current_idx = (current_idx + 1) % Global.shop_items.size()
	show_card_info()
