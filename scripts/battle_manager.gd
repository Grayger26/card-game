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


var opponent_cards_on_battlefield = []
var player_cards_on_battlefied = []

var num_of_player_card_draw
var num_of_opponent_card_draw = 6

var round = 1
var player_hp = STARTING_HEALTH
var player_mana = 0
var player_ult_cost = 10

var opponent_hp = STARTING_HEALTH
var opponent_mana = 2
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


func _process(delta: float) -> void:
	if player_hp < 0:
		player_hp = 0
	elif player_hp > 20:
		player_hp = 20
	
	if player_mana < 0:
		player_mana = 0
	elif player_mana > 20:
		player_mana = 20
	
	if opponent_hp < 0:
		opponent_hp = 0
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
	
	# Если последний раунд то запустить битву карт между собой 
	if round == 3:
		card_fight()


func opponent_turn():
	$"../EndTurnButton".disabled = true
	$"../EndTurnButton".visible = false
	print(number_of_opponent_cards())

	# Check if there is any empty card slots are availabe, if not - end turn
	if empty_card_slots.size() != 0:
		await try_play_mage_card()
	
	# Wait 1 second
	await wait(1.0)
	
	if round == 3:
		# Opponent plays card(s)
		if opponent_cards_on_battlefield.size() != 0:
			var enemy_cards_to_attack = opponent_cards_on_battlefield.duplicate()
			for card in enemy_cards_to_attack:
				if player_cards_on_battlefied.size() == 0:
					direct_attack(card, "Opponent")
				else:
					attack()
	
	end_opponent_turn()


func try_play_mage_card():
	var opp_hand = opponent_hand.opponent_hand
	if opp_hand == []:
		end_opponent_turn()
		return
	# Get random empty card slot
	var random_empty_card_slots = empty_card_slots[randi_range(0, empty_card_slots.size()) -1]
	empty_card_slots.erase(random_empty_card_slots)
	#print(empty_card_slots)
	
	# Play mage card
	var mage_card_mana_steal = opp_hand[0]
	var golden_mage_card = null
	for card in opp_hand:
		if card.mana_steal == 1:
			mage_card_mana_steal = card
		elif card.mana_steal == 1 and card.mana_gain == 1:
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
	#print(empty_card_slots)
	
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
	#print(empty_card_slots)
	
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
	#print(empty_card_slots)
	
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
	#print(empty_card_slots)
	
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
	$"../EndTurnButton".disabled = false
	$"../EndTurnButton".visible = true
	
	num_of_opponent_card_draw = opponent_hand.opponent_hand.size()
	erase_opponent_hand()
	draw_players_cards()


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
	#var new_pos_y 
	#if attacker == "Opponent":
		#new_pos_y = players_ult.position.y
	#else:
		#new_pos_y = opponents_ult.position.y
	
	attacking_card.z_index = 5
	
	#var new_pos = Vector2(attacking_card.position.x, new_pos_y)
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

func attack():
	print("attack")


func wait(wait_time):
	battle_timer.wait_time = wait_time
	battle_timer.start()
	await battle_timer.timeout



func number_of_opponent_cards():
	var number_of_cards : int
	# from 1 to 4 cards
	if round != 3:
		number_of_cards = randi_range(1, 4)
	else:
		number_of_cards = 6 - opponent_cards_on_battlefield.size()
	return number_of_cards

	
