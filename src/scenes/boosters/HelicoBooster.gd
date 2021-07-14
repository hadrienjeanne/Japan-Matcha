extends Booster
class_name HelicoBooster

# effects 
var destroy_effect := preload("res://src/scenes/effects/DestroyEffect.tscn")

func fire(_pos :Vector2 = Vector2.ZERO, _dir: Vector2 = Vector2.ZERO) -> void:
	var grid = get_parent()
	var _best_spot = Vector2(randi()%grid.width, randi()%grid.height)
	while grid.grid[_best_spot.x][_best_spot.y] == null:
		_best_spot = Vector2(randi()%grid.width, randi()%grid.height)
	grid.grid[_best_spot.x][_best_spot.y].matched = true
	grid.damage_specials(_best_spot)
	

func destroy(_col:int, _row:int) -> void:
	#fire(Vector2(_col, _row))
	queue_free()
	var _effect := destroy_effect.instance()
	_effect.position =  get_parent().grid_to_pixel(_col, _row)
	get_parent().add_child(_effect)
