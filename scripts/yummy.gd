extends Area2D

# The jar. Lifecycle:
#   IDLE      sitting on its plinth waiting to be stolen
#   CARRIED   riding on its bearer (a lemming or, after capture, Grizzy)
#   DROPPED   lying on the ground after Grizzy swatted the carrier — only
#             Grizzy can recover it from this state
#   FINISHED  the round has been resolved; ignore everything until reset

enum State { IDLE, CARRIED, DROPPED, FINISHED }

const CARRY_OFFSET_LEMMING := Vector2(0, -28)
const CARRY_OFFSET_GRIZZY := Vector2(0, -44)
# A lemming-carrier wins by getting their centre across this x.
const START_LINE_X := 80.0

var state: int = State.IDLE
var carrier: Node2D = null
var carrier_is_grizzy := false
var home_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("yummy")
	home_pos = global_position

func is_carried() -> bool:
	return state == State.CARRIED

func is_carried_by_lemming() -> bool:
	return state == State.CARRIED and not carrier_is_grizzy

func is_dropped() -> bool:
	return state == State.DROPPED

func _physics_process(_delta: float) -> void:
	match state:
		State.IDLE, State.DROPPED:
			for body in get_overlapping_bodies():
				_try_handle_contact(body)
				if state != State.IDLE and state != State.DROPPED:
					break
		State.CARRIED:
			if carrier == null or not is_instance_valid(carrier):
				_drop_at(global_position)
				return
			var offset := CARRY_OFFSET_GRIZZY if carrier_is_grizzy else CARRY_OFFSET_LEMMING
			global_position = carrier.global_position + offset
			if not carrier_is_grizzy and carrier.global_position.x < START_LINE_X:
				_lemming_won(carrier)

func _try_handle_contact(body: Node) -> void:
	if state == State.CARRIED or state == State.FINISHED:
		return
	if body is Lemming:
		# Once Grizzy has knocked a carrier loose, the round belongs to him —
		# the surviving lemmings are heading home in defeat and can't snatch
		# the jar back.
		if state != State.IDLE:
			return
		var lem := body as Lemming
		if lem.is_stunned() or lem.is_going_home():
			return
		_pick_up_by_lemming(lem)
		return
	# Grizzy's body is a StaticBody2D parented to the Grizzy node.
	if state == State.DROPPED and body.get_parent() and body.get_parent().is_in_group("grizzy"):
		_pick_up_by_grizzy(body.get_parent())

func _pick_up_by_lemming(lemming: Lemming) -> void:
	carrier = lemming
	carrier_is_grizzy = false
	state = State.CARRIED
	global_position = lemming.global_position + CARRY_OFFSET_LEMMING
	# Grizzy is NOT told here — he has to spot the theft for himself.
	var game := get_tree().current_scene
	if game and game.has_method("notify_yummy_taken"):
		game.notify_yummy_taken(lemming)

func _pick_up_by_grizzy(g: Node2D) -> void:
	carrier = g
	carrier_is_grizzy = true
	state = State.CARRIED
	global_position = g.global_position + CARRY_OFFSET_GRIZZY
	if g.has_method("on_yummy_picked_up"):
		g.on_yummy_picked_up()

# Direct-call pickup for Grizzy, who can't rely on Area2D body detection
# alone — moving a StaticBody2D by setting its transform doesn't always
# refresh the area's overlap list in the same frame.
func give_to_grizzy(g: Node2D) -> void:
	if state != State.DROPPED:
		return
	_pick_up_by_grizzy(g)

# Lemming was swatted. Yummy decides whether that swat actually drops it
# (only true if this lemming was the carrier) and lands in place at its
# current visual position, not wherever the lemming's transform is.
func on_carrier_swatted(lemming: Node) -> void:
	if state != State.CARRIED or carrier_is_grizzy or carrier != lemming:
		return
	_drop_at(global_position)

func _drop_at(pos: Vector2) -> void:
	carrier = null
	carrier_is_grizzy = false
	state = State.DROPPED
	global_position = pos
	var game := get_tree().current_scene
	if game and game.has_method("notify_carrier_captured"):
		game.notify_carrier_captured()

func _lemming_won(by: Node) -> void:
	state = State.FINISHED
	var game := get_tree().current_scene
	if game and game.has_method("notify_lemming_escaped"):
		game.notify_lemming_escaped(by)

# Called by Grizzy at the end of his victory walk: jar back on the plinth.
func place_at_home() -> void:
	state = State.FINISHED
	carrier = null
	carrier_is_grizzy = false
	global_position = home_pos

func reset_round() -> void:
	state = State.IDLE
	carrier = null
	carrier_is_grizzy = false
	global_position = home_pos
