class_name Lemming
extends CharacterBody2D

@export var move_speed := 150.0

var spawn_pos: Vector2 = Vector2.ZERO
var stunned := 0.0

func _ready() -> void:
	add_to_group("lemmings")
	spawn_pos = global_position

func get_speed() -> float:
	return velocity.length()

func on_caught_by_grizzy() -> void:
	global_position = spawn_pos
	velocity = Vector2.ZERO
	stunned = 0.7
	modulate = Color(1.0, 0.6, 0.6, 1.0)

func _physics_process(delta: float) -> void:
	if stunned > 0.0:
		stunned -= delta
		if stunned <= 0.0:
			modulate = Color(1, 1, 1, 1)
		velocity = Vector2.ZERO
		move_and_slide()
		return
	_decide_velocity(delta)
	move_and_slide()
	if velocity.length() > 1.0:
		rotation = velocity.angle() + PI / 2

func _decide_velocity(_delta: float) -> void:
	pass  # subclasses override
