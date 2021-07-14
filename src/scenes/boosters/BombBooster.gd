extends Booster
class_name BombBooster

# effects 
var destroy_effect := preload("res://src/scenes/effects/DestroyEffect.tscn")

func fire(_pos :Vector2 = Vector2.ZERO, _dir: Vector2 = Vector2.ZERO) -> void:
	var grid = get_parent()
	for i in [_pos.x, _pos.x-1, _pos.x+1, _pos.x-2, _pos.x+2]:
		for j in [_pos.y, _pos.y-1, _pos.y+1, _pos.y-2, _pos.y+2]:
			if grid.is_in_grid(Vector2(i, j)):
				if grid.grid[i][j] != null:
					grid.grid[i][j].matched = true
					grid.damage_specials(Vector2(i, j))


func destroy(_col:int, _row:int) -> void:
	# fire(Vector2(_col, _row))
	queue_free()
	var _effect := destroy_effect.instance()
	_effect.position =  get_parent().grid_to_pixel(_col, _row)
	get_parent().add_child(_effect)