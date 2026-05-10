extends Lemming

# AI lemming behaviour switches with the phase of the round:
#
#   Yummy on plinth          — sneak toward the jar, freezing whenever
#                              Grizzy's cone catches them.
#   Yummy carried by self    — break for the start line.
#   Yummy carried by friend, — keep mobbing the carrier so the pack
#     Grizzy oblivious         drifts homeward with the prize.
#   Yummy carried by friend, — body-block: shove themselves between
#     Grizzy chasing            Grizzy and the carrier so they take the
#                               saucepan instead of the friend.

@export var caution := 0.85          # 0..1 chance per frame to freeze when watched
@export var jitter_amount := 26.0    # sideways wobble so they don't all conga-line

var grizzy: Node = null
# Per-instance variation in where each AI tries to plant themselves
# during a chase, so they aren't all aiming at the same blocking spot.
var block_along := 0.4
var block_perp := 0.0

func _ready() -> void:
	super._ready()
	grizzy = get_tree().get_first_node_in_group("grizzy")
	move_speed *= randf_range(0.85, 1.05)
	block_along = randf_range(0.25, 0.55)
	block_perp = randf_range(-32.0, 32.0)

func _decide_velocity(_delta: float) -> void:
	var yummy := get_tree().get_first_node_in_group("yummy")
	if yummy == null:
		velocity = Vector2.ZERO
		return

	# Carrying it ourselves — bolt for the start line.
	if yummy.is_carried_by_lemming() and yummy.carrier == self:
		_aim_for(Vector2(40.0, spawn_pos.y))
		return

	# A friend has the jar.
	if yummy.is_carried_by_lemming():
		var friend := yummy.carrier as Node2D
		if grizzy != null and grizzy.has_method("is_chasing") and grizzy.is_chasing(friend):
			_aim_for(_blocking_position(friend))
		else:
			_aim_for(friend.global_position)
		return

	# Jar is on the plinth (or briefly dropped — but in that state the
	# round has been lost and we'll be in go_home anyway). Sneak for it.
	var to_target: Vector2 = yummy.global_position - global_position
	var dist := to_target.length()
	if dist < 6.0:
		velocity = Vector2.ZERO
		return
	var dir := to_target / dist
	if grizzy != null and grizzy.is_looking_at(global_position) and randf() < caution:
		velocity = Vector2.ZERO
		return
	var perp := Vector2(-dir.y, dir.x)
	var wobble := perp * sin(Time.get_ticks_msec() * 0.004 + global_position.x * 0.07) * jitter_amount
	velocity = dir * move_speed + wobble

# Where on the line between Grizzy and the carrier should I plant myself?
# Some way along the segment toward Grizzy (so I'm in the swat arc, not
# behind it), nudged sideways so the squad fans out instead of stacking.
func _blocking_position(friend: Node2D) -> Vector2:
	var g_pos: Vector2 = grizzy.global_position
	var f_pos: Vector2 = friend.global_position
	var along := f_pos - g_pos
	if along.length() < 1.0:
		return g_pos
	var perp := Vector2(-along.y, along.x).normalized()
	return g_pos + along * block_along + perp * block_perp

func _aim_for(target_pos: Vector2) -> void:
	var to_target := target_pos - global_position
	var dist := to_target.length()
	if dist < 4.0:
		velocity = Vector2.ZERO
		return
	velocity = (to_target / dist) * move_speed
