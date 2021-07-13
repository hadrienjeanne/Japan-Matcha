extends Node2D
class_name Piece

onready var move_tween : Tween = $MoveTween
onready var sprite : Sprite = $Sprite
onready var destroy_anim: AnimatedSprite = $DestroyAnimation

export (String) var color

var matched := false setget set_matched

# effects 
# var destroy_effect := preload("res://Scenes/Effects/StarEffect.tscn")

func move(target: Vector2) -> void:
	var _err := move_tween.interpolate_property(self, "position", position, target, 0.3, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	_err = move_tween.start()

func dim() -> void:
	sprite.modulate = Color(1, 1, 1, .6)

func undim() -> void:
	sprite.modulate = Color(1, 1, 1, 1)
	

func set_matched(value: bool) -> void:
	matched = value
	if matched:
		dim()
	else:
		undim()

func destroy(col:int, row:int) -> void:
	destroy_anim.visible = true
	destroy_anim.play("default")
	yield(destroy_anim, "animation_finished")
	queue_free()
	# var _effect := destroy_effect.instance()
	# _effect.position =  get_parent().grid_to_pixel(col, row)
	# get_parent().add_child(_effect)
