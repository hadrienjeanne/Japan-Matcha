extends Node2D

onready var particles := $Particles2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	particles.emitting = true


func _on_Timer_timeout() -> void:
	queue_free()