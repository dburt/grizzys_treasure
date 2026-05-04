extends Lemming

func _decide_velocity(_delta: float) -> void:
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
	velocity = dir * move_speed
