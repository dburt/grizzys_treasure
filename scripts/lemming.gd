class_name Lemming
extends CharacterBody2D

# A lemming has three modes:
#   normal   — input or AI drives _decide_velocity; cone catches and
#              saucepan swats both reset to spawn with a stun.
#   stunned  — recovering from a hit; can't move for a moment.
#   going_home — the round is lost and they're walking back to spawn,
#              ghosting through everyone so Grizzy's recovery walk is
#              unhindered. Stays frozen there until the round resets.

const NORMAL_TINT := Color(1, 1, 1, 1)
const HOME_TINT := Color(0.72, 0.74, 0.80, 1.0)

@export var move_speed := 150.0

var spawn_pos: Vector2 = Vector2.ZERO
var stunned := 0.0
var going_home := false
var _initial_collision_mask := 0

func _ready() -> void:
	add_to_group("lemmings")
	spawn_pos = global_position
	_initial_collision_mask = collision_mask

func get_speed() -> float:
	return velocity.length()

func is_stunned() -> bool:
	return stunned > 0.0

func is_going_home() -> bool:
	return going_home

func on_caught_by_grizzy() -> void:
	# Cone-catch during the patrol phase.
	if going_home:
		return
	_send_to_spawn(0.7, Color(1.0, 0.6, 0.6, 1.0))

func on_swatted_by_grizzy() -> void:
	# Saucepan hit during the chase. Tell the yummy first — it'll drop in
	# place if we were the carrier — *then* teleport us, so the drop
	# position is locked in before our transform moves.
	if going_home:
		return
	var yummy := get_tree().get_first_node_in_group("yummy")
	if yummy and yummy.has_method("on_carrier_swatted"):
		yummy.on_carrier_swatted(self)
	_send_to_spawn(1.4, Color(1.0, 0.45, 0.45, 1.0))

func go_home() -> void:
	if going_home:
		return
	going_home = true
	collision_mask = 0  # ghost through Grizzy and one another
	if stunned <= 0.0:
		modulate = HOME_TINT

func _send_to_spawn(stun_time: float, tint: Color) -> void:
	global_position = spawn_pos
	velocity = Vector2.ZERO
	stunned = stun_time
	modulate = tint

func _physics_process(delta: float) -> void:
	if going_home:
		_walk_home(delta)
		return
	if stunned > 0.0:
		stunned -= delta
		if stunned <= 0.0:
			modulate = NORMAL_TINT
		velocity = Vector2.ZERO
		move_and_slide()
		return
	_decide_velocity(delta)
	move_and_slide()
	if velocity.length() > 1.0:
		rotation = velocity.angle() + PI / 2

func _walk_home(delta: float) -> void:
	if stunned > 0.0:
		stunned -= delta
		if stunned <= 0.0:
			modulate = HOME_TINT
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var to_home := spawn_pos - global_position
	if to_home.length() < 4.0:
		velocity = Vector2.ZERO
	else:
		velocity = (to_home / to_home.length()) * move_speed
	move_and_slide()
	if velocity.length() > 1.0:
		rotation = velocity.angle() + PI / 2

func _decide_velocity(_delta: float) -> void:
	pass  # subclasses override

func reset_round() -> void:
	going_home = false
	stunned = 0.0
	velocity = Vector2.ZERO
	collision_mask = _initial_collision_mask
	modulate = NORMAL_TINT
	rotation = 0.0
	global_position = spawn_pos
