extends Node2D

@onready var menu: Control = $CanvasLayer/Menu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	menu.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Esc"):
		if menu.visible == false:
			menu.visible = true
		else:
			menu.visible = false
		
		


func _on_continue_pressed() -> void:
	menu.visible = false


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()


func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
