extends Node2D
class_name Booster

onready var move_tween : Tween = $MoveTween
onready var sprite : Sprite = $Sprite

var matched := false

func move(target: Vector2) -> void:
	var _err := move_tween.interpolate_property(self, "position", position, target, 0.3, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	_err = move_tween.start()

# func set_matched(value: bool) -> void:
# 	matched = value
# 	if matched:
# 		print_debug("booster matched")

func fire(_pos :Vector2 = Vector2.ZERO, _dir: Vector2 = Vector2.ZERO) -> void:
	pass # logic in derived classes


func destroy(_col:int, _row: int) -> void:
	pass