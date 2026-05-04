extends Area2D

func _ready() -> void:
	add_to_group("yummy")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not (body is Lemming):
		return
	var game := get_tree().current_scene
	if game.has_method("notify_yummy_taken"):
		game.notify_yummy_taken(body)
	body.set_physics_process(false)
