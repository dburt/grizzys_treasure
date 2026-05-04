extends Node2D

# Grizzy stands near the Yummy and periodically turns. While "looking", any
# lemming inside his vision cone that is moving above a small threshold is
# bounced back to spawn.

const VISION_RANGE := 720.0
const VISION_HALF_ANGLE := deg_to_rad(28.0)
const CATCH_SPEED := 12.0

@export var look_min := 1.4
@export var look_max := 3.2
@export var turn_time := 0.55
@export_range(-180.0, 180.0) var initial_facing_degrees := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var cone: Polygon2D = $Cone

enum State { LOOKING, TURNING }

var facing := 0.0
var state: int = State.LOOKING
var t := 0.0
var look_duration := 2.0
var turn_from := 0.0
var turn_to := 0.0
var target_next_turn := true  # alternates: random sweep, then targeted, then random...

func _ready() -> void:
	add_to_group("grizzy")
	sprite.rotation = PI / 2  # sprite art faces "up"; +X is forward in world space
	facing = deg_to_rad(initial_facing_degrees)
	_build_cone_polygon()
	_start_looking()

func _build_cone_polygon() -> void:
	var half_width := VISION_RANGE * tan(VISION_HALF_ANGLE)
	cone.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(VISION_RANGE, -half_width),
		Vector2(VISION_RANGE, half_width),
	])

func _process(delta: float) -> void:
	t += delta
	match state:
		State.LOOKING:
			if t >= look_duration:
				_start_turning()
		State.TURNING:
			var k := clampf(t / turn_time, 0.0, 1.0)
			facing = lerp_angle(turn_from, turn_to, k)
			if k >= 1.0:
				facing = turn_to
				_start_looking()
	rotation = facing
	cone.color = Color(1.0, 0.95, 0.35, 0.22) if state == State.LOOKING else Color(0.5, 0.5, 0.5, 0.10)

func _physics_process(_delta: float) -> void:
	if state != State.LOOKING:
		return
	for lemming in get_tree().get_nodes_in_group("lemmings"):
		if lemming.get_speed() > CATCH_SPEED and is_looking_at(lemming.global_position):
			lemming.on_caught_by_grizzy()

func is_looking_at(world_pos: Vector2) -> bool:
	if state != State.LOOKING:
		return false
	var to_pos := world_pos - global_position
	if to_pos.length() > VISION_RANGE:
		return false
	return absf(angle_difference(facing, to_pos.angle())) < VISION_HALF_ANGLE

func _start_looking() -> void:
	state = State.LOOKING
	t = 0.0
	look_duration = randf_range(look_min, look_max)

func _start_turning() -> void:
	state = State.TURNING
	t = 0.0
	turn_from = facing
	if target_next_turn:
		turn_to = _pick_target_angle()
	else:
		var sweep := randf_range(PI / 3.0, 2.0 * PI / 3.0)
		if randf() < 0.5:
			sweep = -sweep
		turn_to = facing + sweep
	target_next_turn = not target_next_turn

func _pick_target_angle() -> float:
	var yummy_node := get_tree().get_first_node_in_group("yummy") as Node2D
	var best: Lemming = null
	var best_d := INF
	for node in get_tree().get_nodes_in_group("lemmings"):
		var l := node as Lemming
		if l == null:
			continue
		var ref_pos: Vector2 = yummy_node.global_position if yummy_node != null else global_position
		var d := l.global_position.distance_to(ref_pos)
		if d < best_d:
			best_d = d
			best = l
	if best == null:
		return facing + randf_range(-PI / 3.0, PI / 3.0)
	return (best.global_position - global_position).angle()
