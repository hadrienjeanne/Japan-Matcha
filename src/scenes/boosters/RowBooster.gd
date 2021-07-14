extends Booster
class_name RowBooster

# effects 
var destroy_effect := preload("res://src/scenes/effects/DestroyEffect.tscn")

func fire(_pos :Vector2 = Vector2.ZERO, _dir: Vector2 = Vector2.ZERO) -> void:
	var grid = get_parent()
	var _row = _pos.y #+ _dir.y
	# print_debug("destroy row booster: ", _row)
	for i in grid.width:
		if grid.grid[i][_row] != null:
			grid.grid[i][_row].matched = true
			grid.damage_specials(Vector2(i, _row))


func destroy(_col:int, _row:int) -> void:
	# fire(Vector2(_col, _row))
	queue_free()
	var _effect := destroy_effect.instance()
	_effect.position =  get_parent().grid_to_pixel(_col, _row)
	get_parent().add_child(_effect)
