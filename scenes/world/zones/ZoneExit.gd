extends Area2D

@export var target_scene:    String = ""
@export var spawn_point_name: String = "SpawnSouth"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.change_zone(target_scene, spawn_point_name)
