extends Node

const SMALL_CARD_SCALE = 0.7
const CARD_MOVE_SPEED = 0.35
const STARTING_HEALTH = 20

@onready var battle_timer: Timer = $"../BattleTimer"
var empty_card_slots = []
@onready var player_hand: Node2D = $"../PlayerHand"
@onready var card_manager: Node2D = $"../CardManager"
@onready var deck: Node2D = $"../Deck"
@onready var opponent_hand: Node2D = $"../OpponentHand"
@onready var opponent_deck: Node2D = $"../OpponentDeck"

@onready var ui_player_hp: Sprite2D = $"../CanvasLayer/UI/Player_HP"
@onready var ui_opponent_hp: Sprite2D = $"../CanvasLayer/UI/Opponent_HP"

@onready var ui_player_mana: Sprite2D = $"../CanvasLayer/UI/Player_Mana"
@onready var ui_opponent_mana: Sprite2D = $"../CanvasLayer/UI/Opponent_Mana"

@onready var players_ult: TextureButton = $"../CanvasLayer/Characters/PlayersUlt"
@onready var opponents_ult: TextureButton = $"../CanvasLayer/Characters/OpponentsUlt"
@onready var round_label: Label = $"../CanvasLayer/UI/RoundLabel"

@onready var end_turn_button: Button = $"../EndTurnButton"

var player_empty_slots = []


var opponent_cards_on_battlefield = []
var player_cards_on_battlefied = []

var num_of_player_card_draw
var num_of_opponent_card_draw = 6

var round = 1
var player_hp = STARTING_HEALTH
var player_mana = 5
var player_ult_cost = 10

var opponent_hp = STARTING_HEALTH
var opponent_mana = 5
var opponent_ult_cost = 10



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0
	
	empty_card_slots.append($"../CardSlots/EnemyCardSlot1")
	empty_card_slots.append($"../CardSlots/EnemyCardSlot2")
	empty_card_slots.append($"../CardSlots/EnemyCardSlot3")
	empty_card_slots.append($"../CardSlots/EnemyCardSlot4")
	empty_card_slots.append($"../CardSlots/EnemyCardSlot5")
	empty_card_slots.append($"../CardSlots/EnemyCardSlot6")
	
	player_empty_slots.append($"../CardSlots/CardSlot")
	player_empty_slots.append($"../CardSlots/CardSlot2")
	player_empty_slots.append($"../CardSlots/CardSlot3")
	player_empty_slots.append($"../CardSlots/CardSlot4")
	player_empty_slots.append($"../CardSlots/CardSlot5")
	player_empty_slots.append($"../CardSlots/CardSlot6")


func _process(delta: float) -> void:
	if player_hp <= 0:
		player_hp = 0
		win("Opponent")
	elif player_hp > 20:
		player_hp = 20
	
	if player_mana < 0:
		player_mana = 0
	elif player_mana > 20:
		player_mana = 20
	
	if opponent_hp <= 0:
		opponent_hp = 0
		win("Player")
	elif opponent_hp > 20:
		opponent_hp = 20
	
	if opponent_mana < 0:
		opponent_mana = 0
	elif opponent_mana > 20:
		opponent_mana = 20
	
	ui_player_hp.frame = player_hp
	ui_player_mana.frame = player_mana
	
	ui_opponent_hp.frame = opponent_hp
	ui_opponent_mana.frame = opponent_mana
	
	if player_mana < player_ult_cost:
		players_ult.disabled = true
	else:
		players_ult.disabled = false
	
	round_label.text = str(round)

func _on_end_turn_button_pressed() -> void:
	num_of_player_card_draw = player_hand.player_hand.size()
	erase_players_hand()
	draw_opponent_cards()
	opponent_turn()


func opponent_turn():
	end_turn_button.disabled = true
	end_turn_button.visible = false
	var cards_to_play = ["Mage", "Warrior", "Ranger", "Tank", "Spy"]
	# Check if there is any empty card slots are availabe, if not - end turn
	if empty_card_slots.size() != 0:
		for i in number_of_opponent_cards():
			var card_to_play = cards_to_play.pick_random()
			match card_to_play:
				"Mage":
					await try_play_mage_card()
				"Warrior":
					await try_to_play_warrior_card()
				"Ranger":
					await try_to_play_ranger_card()
				"Tank":
					await try_to_play_tank_card()
				"Spy":
					await try_to_play_spy_card()
			
	await wait(1.0)
	if round == 3:
		# Opponent plays card(s)
		if opponent_cards_on_battlefield.size() != 0:
			mana_gain("Opponent")
			mana_gain("Player")
			mana_steal("Opponent")
			mana_steal("Player")
			
			var enemy_cards_to_attack = opponent_cards_on_battlefield.duplicate()
			for card in enemy_cards_to_attack:
				if player_cards_on_battlefied.size() != 0:
					attack(card, "Opponent")
					await wait(0.5)
					
					
			await wait(3.0)
			
			
		if opponent_cards_on_battlefield.size() != 0:
			var opponent_cards_to_attack = opponent_cards_on_battlefield.duplicate()
			for card in opponent_cards_to_attack:
				if card.can_damage == true:
					direct_attack(card, "Opponent")
			
		if player_cards_on_battlefied.size() != 0:
			var player_cards_to_attack = player_cards_on_battlefied.duplicate()
			for card in player_cards_to_attack:
				if card.can_damage == true:
					direct_attack(card, "Player")
	#
	if round != 3:
		end_opponent_turn()


func attack(attacking_card, attacker):
	if attacking_card == null or not is_instance_valid(attacking_card):
		return # Проверяем, что атакующая карта существует

	attacking_card.z_index = 5
	var cards_to_erase = []
	var enemy_cards_to_erase = []
	var used_player_cards = []
	var used_enemy_cards = []

	# Правила атак
	var attack_rules = {
		"Warrior": "Tank",
		"Tank": "Warrior",
		"Ranger": "Spy",
		"Spy": "Ranger"
	}

	# Каждая карта противника атакует карты игрока
	for enemy_card in opponent_cards_on_battlefield.duplicate():
		if enemy_card in used_enemy_cards or not is_instance_valid(enemy_card):
			continue

		for player_card in player_cards_on_battlefied.duplicate():
			if player_card in used_player_cards or not is_instance_valid(player_card):
				continue

			# Применяем правила атак
			if attack_rules.has(enemy_card.type) and attack_rules[enemy_card.type] == player_card.type:
				print(enemy_card.type, "attacks", player_card.type)

				# Добавляем карты для удаления
				cards_to_erase.append(player_card)
				enemy_cards_to_erase.append(enemy_card)

				# Помечаем карты как использованные
				used_player_cards.append(player_card)
				used_enemy_cards.append(enemy_card)

				break  # Переходим к следующей карте противника

	# Удаляем карты из списков
	for card in cards_to_erase:
		if card in player_cards_on_battlefied and is_instance_valid(card):
			print("Deleting player card:", card)
			player_cards_on_battlefied.erase(card)
			card.queue_free()

	for card in enemy_cards_to_erase:
		if card in opponent_cards_on_battlefield and is_instance_valid(card):
			print("Deleting enemy card:", card)
			opponent_cards_on_battlefield.erase(card)
			card.queue_free()

	# Ждем перед восстановлением z_index
	await wait(1.0)

	# Восстанавливаем z_index атакующей карты
	if is_instance_valid(attacking_card):
		attacking_card.z_index = 0





func try_play_mage_card():
	var opp_hand = opponent_hand.opponent_hand
	if opp_hand == []:
		end_opponent_turn()
		return
	# Get random empty card slot
	var random_empty_card_slots = empty_card_slots[randi_range(0, empty_card_slots.size()) -1]
	empty_card_slots.erase(random_empty_card_slots)
	
	# Play mage card
	var mage_card_mana_steal = opp_hand[0]
	var golden_mage_card = null
	for card in opp_hand:
		if card.mana_steal == 1:
			mage_card_mana_steal = card
		if card.mana_steal == 1 and card.mana_gain == 1:
			golden_mage_card = card
	
	if golden_mage_card != null:
		mage_card_mana_steal = golden_mage_card
	
	# Animate card frlip
	var tween = get_tree().create_tween()
	tween.tween_property(mage_card_mana_steal, "position", random_empty_card_slots.position, CARD_MOVE_SPEED)
	
	var tween2 = get_tree().create_tween()
	tween2.tween_property(mage_card_mana_steal, "scale", Vector2(SMALL_CARD_SCALE, SMALL_CARD_SCALE), CARD_MOVE_SPEED)
	
	mage_card_mana_steal.get_node("AnimationPlayer").play("card_flip")
	
	# Remove card from opponent hand
	opponent_hand.remove_card_from_hand(mage_card_mana_steal)
	mage_card_mana_steal.card_slot_card_is_in = random_empty_card_slots
	opponent_cards_on_battlefield.append(mage_card_mana_steal)
	
	# Wait 1 second
	await wait(1.0)


func try_to_play_warrior_card():
	var opp_hand = opponent_hand.opponent_hand
	if opp_hand == []:
		end_opponent_turn()
		return
	# Get random empty card slot
	var random_empty_card_slots = empty_card_slots[randi_range(0, empty_card_slots.size()) -1]
	empty_card_slots.erase(random_empty_card_slots)
	
	# Play mage card
	var mage_card_mana_steal = opp_hand[0]
	var golden_mage_card = null
	for card in opp_hand:
		if card.type == "Warrior":
			mage_card_mana_steal = card
		elif card.type == "Warrior" and card.mana_gain == 1:
			golden_mage_card = card
	
	if golden_mage_card != null:
		mage_card_mana_steal = golden_mage_card
	
	# Animate card frlip
	var tween = get_tree().create_tween()
	tween.tween_property(mage_card_mana_steal, "position", random_empty_card_slots.position, CARD_MOVE_SPEED)
	
	var tween2 = get_tree().create_tween()
	tween2.tween_property(mage_card_mana_steal, "scale", Vector2(SMALL_CARD_SCALE, SMALL_CARD_SCALE), CARD_MOVE_SPEED)
	
	mage_card_mana_steal.get_node("AnimationPlayer").play("card_flip")
	
	# Remove card from opponent hand
	opponent_hand.remove_card_from_hand(mage_card_mana_steal)
	mage_card_mana_steal.card_slot_card_is_in = random_empty_card_slots
	opponent_cards_on_battlefield.append(mage_card_mana_steal)
	
	# Wait 1 second
	await wait(1.0)


func try_to_play_ranger_card():
	var opp_hand = opponent_hand.opponent_hand
	if opp_hand == []:
		end_opponent_turn()
		return
	# Get random empty card slot
	var random_empty_card_slots = empty_card_slots[randi_range(0, empty_card_slots.size()) -1]
	empty_card_slots.erase(random_empty_card_slots)
	
	# Play mage card
	var mage_card_mana_steal = opp_hand[0]
	var golden_mage_card = null
	for card in opp_hand:
		if card.type == "Ranger":
			mage_card_mana_steal = card
		elif card.type == "Ranger" and card.mana_gain == 1:
			golden_mage_card = card
	
	if golden_mage_card != null:
		mage_card_mana_steal = golden_mage_card
	
	# Animate card frlip
	var tween = get_tree().create_tween()
	tween.tween_property(mage_card_mana_steal, "position", random_empty_card_slots.position, CARD_MOVE_SPEED)
	
	var tween2 = get_tree().create_tween()
	tween2.tween_property(mage_card_mana_steal, "scale", Vector2(SMALL_CARD_SCALE, SMALL_CARD_SCALE), CARD_MOVE_SPEED)
	
	mage_card_mana_steal.get_node("AnimationPlayer").play("card_flip")
	
	# Remove card from opponent hand
	opponent_hand.remove_card_from_hand(mage_card_mana_steal)
	mage_card_mana_steal.card_slot_card_is_in = random_empty_card_slots
	opponent_cards_on_battlefield.append(mage_card_mana_steal)
	
	# Wait 1 second
	await wait(1.0)


func try_to_play_tank_card():
	var opp_hand = opponent_hand.opponent_hand
	if opp_hand == []:
		end_opponent_turn()
		return
	# Get random empty card slot
	var random_empty_card_slots = empty_card_slots[randi_range(0, empty_card_slots.size()) -1]
	empty_card_slots.erase(random_empty_card_slots)
	
	# Play mage card
	var mage_card_mana_steal = opp_hand[0]
	var golden_mage_card = null
	for card in opp_hand:
		if card.type == "Tank":
			mage_card_mana_steal = card
		elif card.type == "Tank" and card.mana_gain == 1:
			golden_mage_card = card
	
	if golden_mage_card != null:
		mage_card_mana_steal = golden_mage_card
	
	# Animate card frlip
	var tween = get_tree().create_tween()
	tween.tween_property(mage_card_mana_steal, "position", random_empty_card_slots.position, CARD_MOVE_SPEED)
	
	var tween2 = get_tree().create_tween()
	tween2.tween_property(mage_card_mana_steal, "scale", Vector2(SMALL_CARD_SCALE, SMALL_CARD_SCALE), CARD_MOVE_SPEED)
	
	mage_card_mana_steal.get_node("AnimationPlayer").play("card_flip")
	
	# Remove card from opponent hand
	opponent_hand.remove_card_from_hand(mage_card_mana_steal)
	mage_card_mana_steal.card_slot_card_is_in = random_empty_card_slots
	opponent_cards_on_battlefield.append(mage_card_mana_steal)
	
	# Wait 1 second
	await wait(1.0)
	

func try_to_play_spy_card():
	var opp_hand = opponent_hand.opponent_hand
	if opp_hand == []:
		end_opponent_turn()
		return
	# Get random empty card slot
	var random_empty_card_slots = empty_card_slots[randi_range(0, empty_card_slots.size()) -1]
	empty_card_slots.erase(random_empty_card_slots)
	
	# Play mage card
	var mage_card_mana_steal = opp_hand[0]
	var golden_mage_card = null
	for card in opp_hand:
		if card.type == "Spy":
			mage_card_mana_steal = card
		elif card.type == "Spy" and card.mana_gain == 1:
			golden_mage_card = card
	
	if golden_mage_card != null:
		mage_card_mana_steal = golden_mage_card
	
	# Animate card frlip
	var tween = get_tree().create_tween()
	tween.tween_property(mage_card_mana_steal, "position", random_empty_card_slots.position, CARD_MOVE_SPEED)
	
	var tween2 = get_tree().create_tween()
	tween2.tween_property(mage_card_mana_steal, "scale", Vector2(SMALL_CARD_SCALE, SMALL_CARD_SCALE), CARD_MOVE_SPEED)
	
	mage_card_mana_steal.get_node("AnimationPlayer").play("card_flip")
	
	# Remove card from opponent hand
	opponent_hand.remove_card_from_hand(mage_card_mana_steal)
	mage_card_mana_steal.card_slot_card_is_in = random_empty_card_slots
	opponent_cards_on_battlefield.append(mage_card_mana_steal)
	
	# Wait 1 second
	await wait(1.0)


func end_opponent_turn():
	round += 1
	if round > 3:
		round = 1
	
	num_of_opponent_card_draw = opponent_hand.opponent_hand.size()
	erase_opponent_hand()
	draw_players_cards()
	end_turn_button.disabled = false
	end_turn_button.visible = true
	


func erase_players_hand():
	var all_cards = card_manager.get_children()
	for i in all_cards.size():
		if all_cards[i] in player_hand.player_hand:
			all_cards[i].queue_free()
	player_hand.player_hand = []
	

func erase_opponent_hand():
	var all_cards = card_manager.get_children()
	for i in all_cards.size():
		if all_cards[i] in opponent_hand.opponent_hand:
			all_cards[i].queue_free()
	opponent_hand.opponent_hand = []


func draw_players_cards():
	for i in range(num_of_player_card_draw):
		deck.draw_card()
	num_of_player_card_draw = 0
	

func draw_opponent_cards():
	for i in range(num_of_opponent_card_draw):
		opponent_deck.draw_card()
	num_of_opponent_card_draw = 0


func card_fight():
	pass


func _on_players_ult_mouse_entered() -> void:
	$"../CanvasLayer/Characters/PlayerNote".visible = true


func _on_players_ult_mouse_exited() -> void:
	$"../CanvasLayer/Characters/PlayerNote".visible = false


func _on_opponents_ult_mouse_entered() -> void:
	$"../CanvasLayer/Characters/OpponentNote".visible = true


func _on_opponents_ult_mouse_exited() -> void:
	$"../CanvasLayer/Characters/OpponentNote".visible = false


func _on_players_ult_pressed() -> void:
	# ult
	pass # Replace with function body.


func direct_attack(attacking_card, attacker):
	attacking_card.z_index = 5
	
	var new_pos : Vector2
	
	if attacker == "Opponent":
		new_pos = players_ult.position
	else:
		new_pos = opponents_ult.position
	
	# Attack animation
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card, "position", new_pos, CARD_MOVE_SPEED)
	await wait(0.3)
	
	if attacker == "Opponent":
		player_hp -= 1
	else:
		opponent_hp -= 1
	
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.card_slot_card_is_in.position, CARD_MOVE_SPEED)
	
	await wait(1.0)
	
	attacking_card.z_index = 0
	round = 0
	end_opponent_turn()
	erase_opponent_card_slots()
	erase_players_hand()
	erase_player_card_slots()
	for i in range(deck.STARTING_HAND_SIZE):
		deck.draw_card()


func wait(wait_time):
	battle_timer.wait_time = wait_time
	battle_timer.start()
	await battle_timer.timeout


func number_of_opponent_cards():
	var number_of_cards : int
	# from 1 to 4 cards
	if round == 1:
		number_of_cards = randi_range(1, 3)
		print(number_of_cards)
	elif round == 2:
		number_of_cards = randi_range(1, 3)
		print(number_of_cards)
	else:
		number_of_cards = 6 - opponent_cards_on_battlefield.size()
	return number_of_cards

	
func erase_opponent_card_slots():
	var all_cards = card_manager.get_children()
	for i in all_cards.size():
		if all_cards[i] in opponent_cards_on_battlefield:
			all_cards[i].queue_free()
	opponent_cards_on_battlefield = []
	num_of_opponent_card_draw = 6
	empty_card_slots = []
	empty_card_slots.append($"../CardSlots/EnemyCardSlot1")
	empty_card_slots.append($"../CardSlots/EnemyCardSlot2")
	empty_card_slots.append($"../CardSlots/EnemyCardSlot3")
	empty_card_slots.append($"../CardSlots/EnemyCardSlot4")
	empty_card_slots.append($"../CardSlots/EnemyCardSlot5")
	empty_card_slots.append($"../CardSlots/EnemyCardSlot6")

func erase_player_card_slots():
	var all_cards = card_manager.get_children()
	for i in all_cards.size():
		if all_cards[i] in player_cards_on_battlefied:
			all_cards[i].queue_free()
	var cards_in_slots = $"../CardSlots".get_children()
	for i in cards_in_slots.size():
		if cards_in_slots[i] in player_empty_slots:
			cards_in_slots[i].card_in_slot = false
	player_cards_on_battlefied = []
	num_of_player_card_draw = 6
	player_empty_slots = []
	player_empty_slots.append($"../CardSlots/CardSlot")
	player_empty_slots.append($"../CardSlots/CardSlot2")
	player_empty_slots.append($"../CardSlots/CardSlot3")
	player_empty_slots.append($"../CardSlots/CardSlot4")
	player_empty_slots.append($"../CardSlots/CardSlot5")
	player_empty_slots.append($"../CardSlots/CardSlot6")



func mana_gain(side):
	if side == "Opponent":
		for i in opponent_cards_on_battlefield.size():
			if opponent_cards_on_battlefield[i].mana_gain > 0:
				opponent_mana += opponent_cards_on_battlefield[i].mana_gain
	else:
		for i in player_cards_on_battlefied.size():
			if player_cards_on_battlefied[i].mana_gain > 0:
				player_mana += player_cards_on_battlefied[i].mana_gain


func mana_steal(side):
	if side == "Opponent":
		for i in opponent_cards_on_battlefield.size():
			if opponent_cards_on_battlefield[i].mana_steal > 0:
				if player_mana > 0:
					opponent_mana += opponent_cards_on_battlefield[i].mana_steal
					player_mana -= opponent_cards_on_battlefield[i].mana_steal
				if player_mana < 0:
					player_mana = 0
	else:
		for i in player_cards_on_battlefied.size():
			if player_cards_on_battlefied[i].mana_steal > 0:
				if opponent_mana > 0:
					player_mana += player_cards_on_battlefied[i].mana_steal
					opponent_mana -= player_cards_on_battlefied[i].mana_steal
				if opponent_mana < 0:
					opponent_mana = 0


func ult(side):
	if side == "Opponent":
		if opponent_mana >= opponent_ult_cost:
			pass
		else:
			pass
	else:
		if opponent_mana >= opponent_ult_cost:
			pass
		else:
			pass


func win(side):
	if side == "Opponent":
		print("Opponent won")
	else:
		print("Player won")
