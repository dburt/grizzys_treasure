extends Lemming

# Double-tap a direction within DOUBLE_TAP_WINDOW to dash: a brief burst
# where move_speed is multiplied. Steering still works during the burst.
const DOUBLE_TAP_WINDOW := 0.28
const DASH_DURATION := 0.18
const DASH_MULTIPLIER := 2.4

var _last_tap_dir := Vector2.ZERO
var _last_tap_time := -1.0
var _dash_timer := 0.0

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var dir := _direction_for_key(event.physical_keycode)
	if dir == Vector2.ZERO:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if dir == _last_tap_dir and now - _last_tap_time <= DOUBLE_TAP_WINDOW:
		_dash_timer = DASH_DURATION
		_last_tap_time = -1.0  # consume so triple-tap doesn't chain
	else:
		_last_tap_dir = dir
		_last_tap_time = now

func _direction_for_key(keycode: int) -> Vector2:
	match keycode:
		KEY_W, KEY_UP:
			return Vector2.UP
		KEY_S, KEY_DOWN:
			return Vector2.DOWN
		KEY_A, KEY_LEFT:
			return Vector2.LEFT
		KEY_D, KEY_RIGHT:
			return Vector2.RIGHT
	return Vector2.ZERO

func _decide_velocity(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
		dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
		dir.y += 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		dir.x += 1.0
	if dir != Vector2.ZERO:
		dir = dir.normalized()
	var speed := move_speed
	if _dash_timer > 0.0:
		_dash_timer -= delta
		speed *= DASH_MULTIPLIER
	velocity = dir * speed
