extends Node2D

@onready var hud_label: Label = $HUD/Label
var ended := false

func _ready() -> void:
	_set_status("Steal the Yummy! WASD/arrows to move.")

func _set_status(s: String) -> void:
	hud_label.text = s

func notify_yummy_taken(by: Node) -> void:
	if ended:
		return
	ended = true
	var who: String = "You" if by.name == "PlayerLemming" else String(by.name)
	_set_status("%s grabbed the Yummy!  Press R to replay." % who)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_R:
		get_tree().reload_current_scene()
