extends Lemming

# AI lemming: heads for the Yummy, but freezes when Grizzy looks its way.
# A small caution roll keeps them imperfect — sometimes they get caught.

@export var caution := 0.85          # 0..1 chance per frame to freeze when watched
@export var jitter_amount := 26.0    # sideways wobble so they don't all conga-line

var target: Node2D = null
var grizzy: Node = null

func _ready() -> void:
	super._ready()
	target = get_tree().get_first_node_in_group("yummy")
	grizzy = get_tree().get_first_node_in_group("grizzy")
	move_speed *= randf_range(0.85, 1.05)

func _decide_velocity(_delta: float) -> void:
	if target == null:
		velocity = Vector2.ZERO
		return

	var to_target: Vector2 = target.global_position - global_position
	var dist := to_target.length()
	if dist < 6.0:
		velocity = Vector2.ZERO
		return

	var dir := to_target / dist  # normalized

	if grizzy != null and grizzy.is_looking_at(global_position) and randf() < caution:
		velocity = Vector2.ZERO
		return

	# add a sideways wobble for personality
	var perp := Vector2(-dir.y, dir.x)
	var wobble := perp * sin(Time.get_ticks_msec() * 0.004 + global_position.x * 0.07) * jitter_amount
	velocity = dir * move_speed + wobble
