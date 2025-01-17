extends Node2D

const CARD_SCENE_PATH = "res://cards/OpponentCard.tscn"
const CARD_DRAW_SPEED = 0.3
const STARTING_HAND_SIZE = 6

var opponent_deck = ["Warrior", 
				"Warrior", 
				"Warrior",    
				"Golden Warrior",
				"Ranger",
				"Ranger",
				"Ranger", 
				"Golden Ranger", 
				"Mage", 
				"Mage",
				"Mage",
				"Golden Mage", 
				"Tank",
				"Tank", 
				"Tank",  
				"Golden Tank",
				"Spy", 
				"Spy", 
				"Spy", 
				"Golden Spy",
				]
var card_database_reference
#var drawn_cards_this_turn = false 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	opponent_deck.shuffle()
	card_database_reference = preload("res://scripts/CardDatabase.gd")
	#for i in range(STARTING_HAND_SIZE):
		#draw_card()
		#drawn_cards_this_turn = false
	#drawn_cards_this_turn = true


func draw_card():
	#if drawn_cards_this_turn: # if drawn_cards_this_turn == 6: return (card_drawn_this_turn +=1 after each draw)
		#return
	
	#drawn_cards_this_turn = true
	var card_drawn_name = opponent_deck[0]
	opponent_deck.shuffle()
	#player_deck.erase(card_drawn_name)
	
	if opponent_deck.size() == 0:
		#$Area2D/CollisionShape2D.disabled = true
		$Sprite2D.visible = false
	
	
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	var card_image_path = str("res://assets/cards/" + card_drawn_name + ".png")
	new_card.get_node("Sprite2D").texture = load(card_image_path)
	new_card.get_node("Attack").text = str(card_database_reference.CARDS[card_drawn_name][0])
	new_card.get_node("Health").text = str(card_database_reference.CARDS[card_drawn_name][1])
	new_card.mana_steal = card_database_reference.CARDS[card_drawn_name][2]
	new_card.type = card_database_reference.CARDS[card_drawn_name][4]
	new_card.mana_gain = card_database_reference.CARDS[card_drawn_name][3]
	new_card.get_node("ManaSteal").text = str(new_card.mana_steal)
	new_card.get_node("ManaGain").text = str(card_database_reference.CARDS[card_drawn_name][3])
	$"../CardManager".add_child(new_card)
	new_card.name = "Card"
	$"../OpponentHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
	new_card.get_node("AnimationPlayer").play("card_flip")
