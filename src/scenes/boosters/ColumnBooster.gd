extends Booster
class_name ColumnBooster

# effects 
var destroy_effect := preload("res://src/scenes/effects/DestroyEffect.tscn")

func fire(_pos :Vector2 = Vector2.ZERO, _dir: Vector2 = Vector2.ZERO) -> void:
	var grid = get_parent()
	var _col = _pos.x #+ _dir.x
	# print_debug("destroy col booster:", _col)
	for i in grid.height:
		if grid.grid[_col][i] != null:
			grid.grid[_col][i].matched = true
			grid.damage_specials(Vector2(_col, i))

func destroy(_col:int, _row:int) -> void:
	# fire(Vector2(_col, _row))
	queue_free()
	var _effect := destroy_effect.instance()
	_effect.position =  get_parent().grid_to_pixel(_col, _row)
	get_parent().add_child(_effect)