extends Node2D

# The round director. Owns the phase transitions: pickup, capture, win,
# loss, and the auto-restart that brings everyone back to their starting
# spots for the next attempt.

const RESET_DELAY := 1.6

@onready var hud_label: Label = $HUD/Label
var resetting := false
# Set when a lemming carries the jar across the line. Stays set through
# Grizzy's recovery walk so the final status message names the winner
# instead of crediting Grizzy.
var lemming_winner: Node = null
# Counts down inside _process while a reset is pending. -1 means idle.
# We don't use `await get_tree().create_timer().timeout` because that
# coroutine has been observed not to resume reliably in this scene.
var _reset_countdown := -1.0

func _ready() -> void:
	_set_status("Steal the Yummy and bring it home! WASD/arrows to move.")

func _set_status(s: String) -> void:
	hud_label.text = s

func notify_yummy_taken(by: Node) -> void:
	if resetting:
		return
	var who := "You've" if by.name == "PlayerLemming" else "%s has" % String(by.name)
	_set_status("%s got the Yummy — sneak it home before Grizzy spots you!" % who)

func notify_carrier_captured() -> void:
	if resetting:
		return
	_set_status("Grizzy caught the carrier! He's taking the Yummy back.")
	var grizzy := get_tree().get_first_node_in_group("grizzy")
	if grizzy and grizzy.has_method("on_carrier_captured"):
		grizzy.on_carrier_captured()
	for lem in get_tree().get_nodes_in_group("lemmings"):
		if lem.has_method("go_home"):
			lem.go_home()

func notify_lemming_escaped(by: Node) -> void:
	if resetting or lemming_winner != null:
		return
	lemming_winner = by
	var who: String = "You" if by.name == "PlayerLemming" else String(by.name)
	_set_status("%s made it home with the Yummy! Grizzy's coming back for it…" % who)
	# Reuse the carrier-captured recovery walk: lemmings stroll home and
	# Grizzy fetches the dropped jar, returns it to the plinth, and walks
	# back to his spot — that's when the round resets.
	var grizzy := get_tree().get_first_node_in_group("grizzy")
	if grizzy and grizzy.has_method("on_carrier_captured"):
		grizzy.on_carrier_captured()
	for lem in get_tree().get_nodes_in_group("lemmings"):
		if lem.has_method("go_home"):
			lem.go_home()

func notify_grizzy_won() -> void:
	if resetting:
		return
	if lemming_winner != null:
		var who: String = "You" if lemming_winner.name == "PlayerLemming" else String(lemming_winner.name)
		_set_status("%s won the round! New round starting…" % who)
	else:
		_set_status("Grizzy got his Yummy back! New round starting…")
	_schedule_reset()

func _process(delta: float) -> void:
	if _reset_countdown > 0.0:
		_reset_countdown -= delta
		if _reset_countdown <= 0.0:
			_reset_countdown = -1.0
			_reset_round()
			resetting = false

func _schedule_reset() -> void:
	if resetting:
		return
	resetting = true
	_reset_countdown = RESET_DELAY

func _reset_round() -> void:
	# Lemmings first so they release any references the jar might check.
	for lem in get_tree().get_nodes_in_group("lemmings"):
		if lem.has_method("reset_round"):
			lem.reset_round()
	var yummy := get_tree().get_first_node_in_group("yummy")
	if yummy and yummy.has_method("reset_round"):
		yummy.reset_round()
	var grizzy := get_tree().get_first_node_in_group("grizzy")
	if grizzy and grizzy.has_method("reset_round"):
		grizzy.reset_round()
	lemming_winner = null
	_set_status("Steal the Yummy and bring it home! WASD/arrows to move.")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_R:
		get_tree().reload_current_scene()
