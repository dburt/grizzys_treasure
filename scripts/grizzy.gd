extends Node2D

# Grizzy has four phases, in order:
#
#   LOOKING / TURNING — patrolling. Cone of vision is active; lemmings
#       caught moving through it bounce back to spawn. Forward and
#       backward facings alternate. He's oblivious to the theft until his
#       cone covers a lemming who's already carrying the jar.
#   CHASING — he's seen the carrier. Cone off, saucepan out. He pursues
#       that specific lemming and swats anyone in the arc; only the
#       carrier going down ends the chase. Other swats just clear the
#       path.
#   RECOVERING — carrier is captured, jar dropped. Grizzy walks unhindered
#       to the jar, picks it up, returns it to the plinth, and walks home.
#       Touching this finalises the round in his favour.

const VISION_RANGE := 720.0
const VISION_HALF_ANGLE := deg_to_rad(75.0)  # 150° total arc
const CATCH_SPEED := 12.0

const SWAT_REACH := 110.0
const SWAT_HALF_ARC := deg_to_rad(55.0)
const SAUCEPAN_REST_ROT := -0.6
const SAUCEPAN_SWING_ROT := 1.4

const BODY_LAYER_ACTIVE := 1

@export var look_min := 1.4
@export var look_max := 3.2
@export var turn_time := 0.55
# "Forward" facing — the direction Grizzy points when not watching the
# lemmings. Backward is the opposite (forward + 180°).
@export_range(-180.0, 180.0) var initial_facing_degrees := 0.0

@export var chase_speed := 230.0
@export var chase_turn_rate := 7.0
@export var swat_cooldown := 0.85
@export var swat_duration := 0.32
@export var recover_speed := 175.0
@export var recover_turn_rate := 9.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var cone: Polygon2D = $Cone
@onready var saucepan: Node2D = $Saucepan
@onready var body: StaticBody2D = $Body

enum State { LOOKING, TURNING, CHASING, RECOVERING }
enum RecoverStep { FETCH, RETURN_JAR, GO_HOME, DONE }

var facing := 0.0
var state: int = State.LOOKING
var t := 0.0
var look_duration := 2.0
var turn_from := 0.0
var turn_to := 0.0
var forward_angle := 0.0
var facing_backward := false

var swat_timer := 0.0
var swat_anim := 0.0
var swat_did_hit := false

var target_carrier: Node2D = null
var home_pos: Vector2 = Vector2.ZERO
var recover_step: int = RecoverStep.FETCH

func _ready() -> void:
	add_to_group("grizzy")
	sprite.rotation = PI / 2  # sprite art faces "up"; +X is forward in world space
	forward_angle = deg_to_rad(initial_facing_degrees)
	facing = forward_angle
	home_pos = global_position
	_build_cone_polygon()
	_build_saucepan()
	saucepan.visible = false
	saucepan.rotation = SAUCEPAN_REST_ROT
	_start_looking()

func _build_cone_polygon() -> void:
	var half_width := VISION_RANGE * tan(VISION_HALF_ANGLE)
	cone.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(VISION_RANGE, -half_width),
		Vector2(VISION_RANGE, half_width),
	])

func _build_saucepan() -> void:
	var handle := Polygon2D.new()
	handle.color = Color(0.40, 0.26, 0.16, 1.0)
	handle.polygon = PackedVector2Array([
		Vector2(28, -3.5), Vector2(60, -3.5),
		Vector2(60, 3.5), Vector2(28, 3.5),
	])
	saucepan.add_child(handle)

	var pan := Polygon2D.new()
	pan.color = Color(0.32, 0.33, 0.36, 1.0)
	pan.polygon = _circle_polygon(Vector2(74, 0), 18.0, 14)
	saucepan.add_child(pan)

	var rim := Polygon2D.new()
	rim.color = Color(0.62, 0.64, 0.68, 1.0)
	rim.polygon = _ring_polygon(Vector2(74, 0), 18.0, 14.0, 14)
	saucepan.add_child(rim)

func _circle_polygon(centre: Vector2, radius: float, sides: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in sides:
		var a := TAU * float(i) / float(sides)
		pts.append(centre + Vector2(cos(a), sin(a)) * radius)
	return pts

func _ring_polygon(centre: Vector2, outer: float, inner: float, sides: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in sides:
		var a := TAU * float(i) / float(sides)
		pts.append(centre + Vector2(cos(a), sin(a)) * outer)
	for i in range(sides - 1, -1, -1):
		var a := TAU * float(i) / float(sides)
		pts.append(centre + Vector2(cos(a), sin(a)) * inner)
	return pts

func _process(delta: float) -> void:
	t += delta
	match state:
		State.LOOKING:
			if _notices_theft():
				_start_chasing()
			elif t >= look_duration:
				_start_turning()
		State.TURNING:
			var k := clampf(t / turn_time, 0.0, 1.0)
			facing = lerp_angle(turn_from, turn_to, k)
			if k >= 1.0:
				facing = turn_to
				_start_looking()
		State.CHASING:
			_process_chase(delta)
		State.RECOVERING:
			_process_recover(delta)
	rotation = facing
	if state == State.LOOKING or state == State.TURNING:
		cone.color = Color(1.0, 0.95, 0.35, 0.22) if state == State.LOOKING else Color(0.5, 0.5, 0.5, 0.10)

func _physics_process(_delta: float) -> void:
	if state != State.LOOKING:
		return
	# Spotting the carrier is what *triggers* phase 2 (handled in _process
	# via _notices_theft) — the cone-catch must not also bounce them home,
	# otherwise the player loses their prize the instant they're seen.
	var carrier_lemming: Node = null
	var yummy := get_tree().get_first_node_in_group("yummy")
	if yummy and yummy.is_carried_by_lemming():
		carrier_lemming = yummy.carrier
	for lemming in get_tree().get_nodes_in_group("lemmings"):
		if lemming == carrier_lemming:
			continue
		if lemming.get_speed() > CATCH_SPEED and is_looking_at(lemming.global_position):
			lemming.on_caught_by_grizzy()

func is_looking_at(world_pos: Vector2) -> bool:
	if state != State.LOOKING:
		return false
	return _can_see(world_pos)

func _can_see(world_pos: Vector2) -> bool:
	var to_pos := world_pos - global_position
	if to_pos.length() > VISION_RANGE:
		return false
	return absf(angle_difference(facing, to_pos.angle())) < VISION_HALF_ANGLE

func is_chasing(lemming: Node) -> bool:
	return state == State.CHASING and target_carrier == lemming

# Each LOOKING tick: did our cone just catch a lemming who's already
# carrying the jar? That's the only way Grizzy ever discovers the theft.
func _notices_theft() -> bool:
	var yummy := get_tree().get_first_node_in_group("yummy")
	if yummy == null or not yummy.is_carried_by_lemming():
		return false
	return _can_see(yummy.global_position)

func _start_chasing() -> void:
	var yummy := get_tree().get_first_node_in_group("yummy")
	if yummy == null or yummy.carrier == null:
		return
	target_carrier = yummy.carrier
	state = State.CHASING
	cone.visible = false
	saucepan.visible = true
	swat_timer = 0.0
	swat_anim = 0.0
	swat_did_hit = false
	sprite.modulate = Color(1.0, 0.78, 0.78, 1.0)

func _process_chase(delta: float) -> void:
	# Chase the specific lemming who took the jar. If they've handed it
	# off (e.g. swatted in a multi-lemming pile), retarget to whoever's
	# carrying now.
	var yummy := get_tree().get_first_node_in_group("yummy")
	if target_carrier == null or not is_instance_valid(target_carrier) \
			or (target_carrier as Lemming).is_going_home():
		if yummy and yummy.is_carried_by_lemming():
			target_carrier = yummy.carrier
		else:
			target_carrier = null

	if target_carrier != null:
		var to_aim: Vector2 = target_carrier.global_position - global_position
		var dist := to_aim.length()
		if dist > 1.0:
			var dir := to_aim / dist
			facing = lerp_angle(facing, dir.angle(), clampf(delta * chase_turn_rate, 0.0, 1.0))
			if dist > SWAT_REACH * 0.55:
				global_position += dir * chase_speed * delta

	swat_timer = maxf(swat_timer - delta, 0.0)
	if swat_anim > 0.0:
		swat_anim -= delta
		var k := 1.0 - clampf(swat_anim / swat_duration, 0.0, 1.0)
		saucepan.rotation = lerp(SAUCEPAN_REST_ROT, SAUCEPAN_SWING_ROT, k)
		if not swat_did_hit and k >= 0.55:
			swat_did_hit = true
			_do_swat_hit()
		if swat_anim <= 0.0:
			swat_anim = 0.0
			swat_did_hit = false
			saucepan.rotation = SAUCEPAN_REST_ROT
	else:
		saucepan.rotation = lerp_angle(saucepan.rotation, SAUCEPAN_REST_ROT, clampf(delta * 8.0, 0.0, 1.0))
		if swat_timer <= 0.0 and _has_swattable_in_arc():
			swat_anim = swat_duration
			swat_timer = swat_cooldown
			swat_did_hit = false

func _has_swattable_in_arc() -> bool:
	for lem in get_tree().get_nodes_in_group("lemmings"):
		if (lem as Lemming).is_going_home():
			continue
		if _in_swat_arc(lem.global_position):
			return true
	return false

func _in_swat_arc(world_pos: Vector2) -> bool:
	var to := world_pos - global_position
	if to.length() > SWAT_REACH:
		return false
	return absf(angle_difference(facing, to.angle())) <= SWAT_HALF_ARC

func _do_swat_hit() -> void:
	for lem in get_tree().get_nodes_in_group("lemmings"):
		if (lem as Lemming).is_going_home():
			continue
		if not _in_swat_arc(lem.global_position):
			continue
		if lem.has_method("on_swatted_by_grizzy"):
			lem.on_swatted_by_grizzy()

# Game broadcasts this when the jar is knocked loose. Switch to a calm
# victory walk: fetch the jar, return it, head home.
func on_carrier_captured() -> void:
	if state == State.RECOVERING:
		return
	state = State.RECOVERING
	saucepan.visible = false
	sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	target_carrier = null
	swat_anim = 0.0
	swat_timer = 0.0
	swat_did_hit = false
	# We stay solid here — the yummy's Area2D needs to see our body to
	# register the pickup. The lemmings' go_home() drops their own mask
	# so they ghost past us; that's how the walk stays unhindered.
	recover_step = RecoverStep.FETCH

# Called by Yummy when our body contact picks it up off the ground.
func on_yummy_picked_up() -> void:
	if state == State.RECOVERING and recover_step == RecoverStep.FETCH:
		recover_step = RecoverStep.RETURN_JAR

func _process_recover(delta: float) -> void:
	var yummy := get_tree().get_first_node_in_group("yummy")
	if yummy == null:
		return
	var aim: Vector2
	match recover_step:
		RecoverStep.FETCH:
			aim = yummy.global_position
		RecoverStep.RETURN_JAR:
			aim = yummy.home_pos
			# Yummy is riding us with a carry offset; once it lines up with
			# the plinth, set it down and start walking off.
			if yummy.global_position.distance_to(yummy.home_pos) < 6.0:
				yummy.place_at_home()
				recover_step = RecoverStep.GO_HOME
				return
		RecoverStep.GO_HOME:
			aim = home_pos
			if global_position.distance_to(aim) < 4.0:
				recover_step = RecoverStep.DONE
				_finish_grizzy_win()
				return
		RecoverStep.DONE:
			return

	var to_aim := aim - global_position
	var dist := to_aim.length()
	if dist > 1.0:
		var dir := to_aim / dist
		facing = lerp_angle(facing, dir.angle(), clampf(delta * recover_turn_rate, 0.0, 1.0))
		var step_len := minf(recover_speed * delta, dist)
		global_position += dir * step_len

func _finish_grizzy_win() -> void:
	var game := get_tree().current_scene
	if game and game.has_method("notify_grizzy_won"):
		game.notify_grizzy_won()

func _start_looking() -> void:
	state = State.LOOKING
	t = 0.0
	look_duration = randf_range(look_min, look_max)

func _start_turning() -> void:
	state = State.TURNING
	t = 0.0
	turn_from = facing
	facing_backward = not facing_backward
	turn_to = forward_angle + (PI if facing_backward else 0.0)

func reset_round() -> void:
	global_position = home_pos
	facing_backward = false
	facing = forward_angle
	rotation = facing
	target_carrier = null
	cone.visible = true
	saucepan.visible = false
	saucepan.rotation = SAUCEPAN_REST_ROT
	body.collision_layer = BODY_LAYER_ACTIVE
	sprite.modulate = Color(1, 1, 1, 1)
	swat_anim = 0.0
	swat_timer = 0.0
	swat_did_hit = false
	recover_step = RecoverStep.FETCH
	_start_looking()
