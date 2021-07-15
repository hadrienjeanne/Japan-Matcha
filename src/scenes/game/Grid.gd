extends Node2D
# grid is placed 

# warning-ignore-all:narrowing-conversion

onready var destroy_timer : Timer = $DestroyTimer
onready var collapse_timer : Timer = $CollapseTimer
onready var refill_timer : Timer = $RefillTimer
onready var move_timer : Timer = $MoveTimer

# grid params
export (int) var width := 9
export (int) var height := 9
export (int) var cell_size := 96
export (int) var spawn_offset := 2

var grid := []
var current_matches := []

var grid_cell_background_scene := preload("res://src/scenes/ui/CellBackground.tscn")

# obstacles
export (PoolVector2Array) var empty_spaces := []

# pieces and boosters
var pieces = [
	preload("res://src/scenes/pieces/BluePiece.tscn"),
	preload("res://src/scenes/pieces/GreenPiece.tscn"),
	preload("res://src/scenes/pieces/BrownPiece.tscn"),
	preload("res://src/scenes/pieces/RedPiece.tscn"),
	preload("res://src/scenes/pieces/YellowPiece.tscn"),
]
enum {BLUE, GREEN, BROWN, RED, YELLOW}

var boosters = [
	preload("res://src/scenes/boosters/RowBooster.tscn"),
	preload("res://src/scenes/boosters/ColumnBooster.tscn"),
	preload("res://src/scenes/boosters/BombBooster.tscn"),
	preload("res://src/scenes/boosters/ColorBooster.tscn"),
	preload("res://src/scenes/boosters/HelicoBooster.tscn"),
]

enum {ROW_BOOSTER, COL_BOOSTER, BOMB_BOOSTER, COLOR_BOOSTER, HELICO_BOOSTER}

# State machine 
enum {WAIT, MOVE}
var state := MOVE

# touch variables
var first_touch := Vector2.ZERO
var final_touch := Vector2.ZERO
var controlling_piece := false
var piece_one = null
var piece_two = null

# signals
signal game_over
signal game_won
signal piece_destroyed
signal col_booster_destroyed
signal row_booster_destroyed
signal bomb_booster_destroyed
signal color_booster_destroyed
signal move_played

# level
export (int) var moves := 15
var conditions_fulfilled := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state = MOVE
	grid = make_2d_array(width, height)
	draw_background()
	spawn_pieces(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if state == MOVE:
		touch_input()

func touch_input() -> void:
	if Input.is_action_just_pressed("ui_touch"):
		if is_in_grid(pixel_to_grid(get_global_mouse_position().x - position.x, get_global_mouse_position().y - position.y)):
			controlling_piece = true
			first_touch = pixel_to_grid(get_global_mouse_position().x - position.x, get_global_mouse_position().y - position.y)
	if Input.is_action_just_released("ui_touch"):
		if is_in_grid(pixel_to_grid(get_global_mouse_position().x - position.x, get_global_mouse_position().y - position.y)) && controlling_piece:
			controlling_piece = false
			final_touch = pixel_to_grid(get_global_mouse_position().x - position.x, get_global_mouse_position().y - position.y)
			var direction := touch_direction(first_touch, final_touch)
			swap_pieces(int(first_touch.x), int(first_touch.y), direction)
			move_timer.start()
			if find_matches():
				moves -= 1
				emit_signal("move_played", moves)
				propagate_matched_boosters()
				destroy_timer.start()
			else:
				yield(move_timer, "timeout")
				swap_pieces(int(first_touch.x), int(first_touch.y), direction)
				state = MOVE

# fills in the grid with random pieces
# if avoid_matches is true, avoid the creation of matches on the board
func spawn_pieces(avoid_matches: bool) -> void:
	for i in width:
		for j in height:
			if !has_restricted_fill(Vector2(i, j)):
				if grid[i][j] == null:
					var rand : int = Player.rng.randi_range(0, pieces.size()-1)
					var p = pieces[rand].instance()
					if avoid_matches:
						while match_at(i, j, p.color):
							rand = Player.rng.randi_range(0, pieces.size()-1)
							p = pieces[rand].instance()				
					add_child(p)
					p.position = grid_to_pixel(i, j + spawn_offset)
					p.move(grid_to_pixel(i, j))
					grid[i][j] = p
	if find_matches():
		propagate_matched_boosters()
		destroy_timer.start()
		
	else: # new turn
		if moves > 0:
			# TODO SLIMES
			# if !slime_holder.slime_damaged_during_turn && state == WAIT:
			# 	slime_holder.generate_slime()
			# slime_holder.slime_damaged_during_turn = false
			state = MOVE
		else: # game over
			if conditions_fulfilled:
				emit_signal("game_won")
				print_debug("game won")
			else:
				emit_signal("game_over")
				print_debug("game over")
	

# swaps between the piece at position (col, row) and the piece in the direction passed in arguement
func swap_pieces(col:int, row: int, direction: Vector2) -> void:
	piece_one = grid[col][row]
	piece_two = grid[col + direction.x][row + direction.y]
	if piece_two != null and piece_two != null:
		if !has_restricted_move(Vector2(col, row)) and !has_restricted_move(Vector2(col, row) + direction):
			state = WAIT
			grid[col][row] = piece_two
			grid[col + direction.x][row + direction.y] = piece_one
			piece_one.move(Vector2(grid_to_pixel(col + int(direction.x), row + int(direction.y))))
			piece_two.move(Vector2(grid_to_pixel(col, row)))

# checks if spawning a piece a the position (col, row) would create a 3-match	
func match_at(col: int, row: int, color: String) -> bool:
	# check left
	if col > 1:
		var left_piece = grid[col - 1][row]
		var left2_piece = grid[col - 2][row]
		if left_piece != null && left2_piece != null:
			if left_piece.color == color && left2_piece.color == color:
				return true
	# check below
	if row > 1:
		var below_piece = grid[col][row - 1]
		var below2_piece = grid[col][row - 2]
		if below_piece != null && below2_piece != null:
			if below_piece.color == color && below2_piece.color == color:
				return true

	# check square
	if row > 0 and col > 0 :
		var left_piece = grid[col - 1][row]
		var below_piece = grid[col][row - 1]
		var below_left_piece = grid[col - 1][row - 1]
		if left_piece != null && below_left_piece != null && below_piece != null:
			if left_piece.color == color && below_piece.color == color && below_left_piece.color == color:
				return true
	return false

func draw_background() -> void:
	for i in width:
		for j in height:
			if not is_in_array(empty_spaces, Vector2(i, j)):
				var cell_background = grid_cell_background_scene.instance()
				cell_background.position = grid_to_pixel(i, j)
				add_child(cell_background)
	

# destroy matched pieces	
func destroy_matched() -> void:
	find_boosters()
	for i in width:
		for j in height:
			var _piece = grid[i][j]
			if _piece != null and _piece.matched: # piece or booster to restrict to pieces only: and _piece.is_in_group("Piece"):
				damage_specials(Vector2(i, j))
				if _piece.is_in_group("Piece"):
					# _piece.destroy(i, j)
					emit_signal("piece_destroyed", _piece.color)
				elif _piece.is_in_group("Booster"):
					_piece.fire(Vector2(i, j))
					if _piece.is_in_group("ColBooster"):
						emit_signal("col_booster_destroyed")
					elif _piece.is_in_group("RowBooster"):
						emit_signal("row_booster_destroyed")
					elif _piece.is_in_group("BombBooster"):
						emit_signal("bomb_booster_destroyed")
					elif _piece.is_in_group("ColorBooster"):
						emit_signal("color_booster_destroyed")					
				_piece.destroy(i, j)
				grid[i][j] = null
	collapse_timer.start()
	current_matches.clear()

# browse grid to find matches
func find_matches() -> bool:
	var found_match = false
	# if we swapped a booster, make it a match
	if piece_one != null and piece_two != null and is_instance_valid(piece_one) and is_instance_valid(piece_two):
		if piece_one.is_in_group("Booster") and piece_two.is_in_group("Piece"):
			piece_one.matched = true
			found_match = true
		elif piece_one.is_in_group("Piece") and piece_two.is_in_group("Booster"):
			piece_two.matched = true
			found_match = true
		elif piece_one.is_in_group("Booster") and piece_two.is_in_group("Booster"):
			piece_one.matched = true
			piece_two.matched = true
			print_debug("mixed booster")
			# TODO soucis
			found_match = true
	if !found_match:
		for i in width:
			for j in height:
				if grid[i][j] != null:
					if grid[i][j].is_in_group("Piece"):
						var current_color = grid[i][j].color
						if i > 0 and i < width - 1:
							if grid[i-1][j] != null and grid[i+1][j] != null and grid[i-1][j].is_in_group("Piece") and grid[i+1][j].is_in_group("Piece"):
								if grid[i-1][j].color == current_color and grid[i+1][j].color == current_color:
									grid[i-1][j].set_matched(true)
									grid[i][j].set_matched(true)
									grid[i+1][j].set_matched(true)
									found_match = true
									if !current_matches.has(Vector2(i-1, j)):
										current_matches.append(Vector2(i-1, j))
									if !current_matches.has(Vector2(i, j)):
										current_matches.append(Vector2(i, j))
									if !current_matches.has(Vector2(i+1, j)):
										current_matches.append(Vector2(i+1, j))
						if j > 0 and j < height - 1:
							if grid[i][j-1] != null and grid[i][j+1] != null and grid[i][j-1].is_in_group("Piece") and grid[i][j+1].is_in_group("Piece"):
								if grid[i][j-1].color == current_color and grid[i][j+1].color == current_color:
									grid[i][j-1].set_matched(true)
									grid[i][j].set_matched(true)
									grid[i][j+1].set_matched(true)
									found_match = true
									if !current_matches.has(Vector2(i, j-1)):
										current_matches.append(Vector2(i, j-1))
									if !current_matches.has(Vector2(i, j)):
										current_matches.append(Vector2(i, j))
									if !current_matches.has(Vector2(i, j+1)):
										current_matches.append(Vector2(i, j+1))
						# square matches
						if i >= 0 and i < width - 1 and j >= 0 and j < height - 1:
							if grid[i][j+1] != null and grid[i][j+1].is_in_group("Piece") and grid[i+1][j] != null and grid[i+1][j].is_in_group("Piece") and grid[i+1][j+1] != null and grid[i+1][j+1].is_in_group("Piece"):
								if grid[i][j+1].color == current_color and grid[i+1][j].color == current_color and grid[i+1][j+1].color == current_color:
									grid[i][j].set_matched(true)
									grid[i+1][j].set_matched(true)
									grid[i][j+1].set_matched(true)
									grid[i+1][j+1].set_matched(true)
									found_match = true
									if !current_matches.has(Vector2(i, j)):
										current_matches.append(Vector2(i, j))
									if !current_matches.has(Vector2(i, j+1)):
										current_matches.append(Vector2(i, j+1))
									if !current_matches.has(Vector2(i+1, j)):
										current_matches.append(Vector2(i+1, j))
									if !current_matches.has(Vector2(i+1, j+1)):
										current_matches.append(Vector2(i+1, j+1))
	return found_match

# searches for bombs in the current_matches array
func find_boosters() -> Array:
	var found_boosters := []
	
	if current_matches.size() > 3:
			
		for pos in current_matches:
			var _col : int = pos.x
			var _row : int = pos.y
			if grid[_col][_row].is_in_group("Piece"):
				var _color :String = grid[_col][_row].color
				
				var _col_matched := 0
				var _row_matched := 0
				
				for pos2 in current_matches:
					var _this_col : int = pos2.x
					var _this_row : int = pos2.y				
					if grid[_this_col][_this_row].is_in_group("Piece"):
						var _this_color : String = grid[_this_col][_this_row].color
						if _this_col == _col and _this_color == _color:
							_col_matched += 1
						if _this_row == _row and _this_color == _color:
							_row_matched += 1
				print_debug("matches: ", current_matches, " col matched: ", _col_matched, " row matched: ", _row_matched)
				if _col_matched == 5 or _row_matched == 5:
					make_booster(COLOR_BOOSTER)
					found_boosters.append(COLOR_BOOSTER)
					break
				elif _row_matched == 4:
					make_booster(COL_BOOSTER)
					found_boosters.append(COL_BOOSTER)
					break
				elif _col_matched == 4:
					make_booster(ROW_BOOSTER)
					found_boosters.append(ROW_BOOSTER)
					break
				elif _row_matched >= 3 and _col_matched >= 3:
					make_booster(BOMB_BOOSTER)
					found_boosters.append(BOMB_BOOSTER)
					break
				elif (_row_matched == 2 and _col_matched >= 2) or (_row_matched >= 2 and _col_matched == 2):
					make_booster(HELICO_BOOSTER)
					found_boosters.append(HELICO_BOOSTER)
					break
			if found_boosters.size() > 0:
				break
	return found_boosters

# make the swapped piece (piece_one or piece_two) the booster of type type
func make_booster(type: int) -> void:
	var booster_made := false
	for pos in current_matches:
		var _col :int = pos.x
		var _row :int = pos.y
		if grid[_col][_row] == piece_one:
			# make piece_one a booster
			piece_one.queue_free()
			var b = boosters[type].instance()
			add_child(b)
			b.position = grid_to_pixel(_col, _row)
			grid[_col][_row] = b
			booster_made = true
		elif grid[_col][_row] == piece_two:
			# make piece_two a booster
			piece_two.queue_free()
			var b = boosters[type].instance()
			add_child(b)
			b.position = grid_to_pixel(_col, _row)
			grid[_col][_row] = b
			booster_made = true
	if !booster_made:
		var _col :int = current_matches[0].x
		var _row :int = current_matches[0].y
		grid[_col][_row].queue_free()
		var b = boosters[type].instance()
		add_child(b)
		b.position = grid_to_pixel(_col, _row)
		grid[_col][_row] = b

# damage of special pieces
func damage_specials(pos: Vector2) -> void:
	var damaged : bool
	# damaged = ice_holder.damage(pos)
	# damaged = lock_holder.damage(pos)
	# damaged = concrete_holder.damage(pos)
	# damaged = slime_holder.damage(pos)
	# if damaged:
	# 	slime_holder.slime_damaged_during_turn = true

# collapsing of columns
func collapse_columns() -> void:
	for i in width:
		for j in height:
			if grid[i][j] == null && !has_restricted_fill(Vector2(i, j)):
				for k in range(j+1, height):
					if grid[i][k] != null:
						grid[i][k].move(grid_to_pixel(i, j))
						grid[i][j] = grid[i][k]
						grid[i][k] = null
						break
	refill_timer.start()

func propagate_matched_boosters() -> bool:
	var matches := false
	for i in width:
		for j in height:
			if grid[i][j] != null and grid[i][j].is_in_group("Booster"):
				if grid[i][j].matched:					
					grid[i][j].fire(Vector2(i, j))
					# grid[i][j].destroy(i, j)
					matches = true
	# destroy_matched() # TODO, is it necessary ? bugs without?
	return matches

##
## Signal timers
##

func _on_DestroyTimer_timeout() -> void:
	destroy_matched()

func _on_CollapseTimer_timeout() -> void:
	collapse_columns()

func _on_RefillTimer_timeout() -> void:
	spawn_pieces(false)

##
##  Helpers functions
##

# input: a column and a row number for a piece
# output: the position in pixels of the piece
func grid_to_pixel(col: int, row: int) -> Vector2:
	var new_x := cell_size * col
	var new_y := -cell_size * row
	return Vector2(new_x, new_y)

# input: a position in pixels of the mouse 
# output: the column and the row number for the piece
func pixel_to_grid(x: float, y: float) -> Vector2:
	var col := round(x / float(cell_size))
	var row := round(y / float(-cell_size))
	return Vector2(col, row)

# tells whether the position pos is inside the grid 
func is_in_grid(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < width and pos.y < height

# tells whether an item is in an array
func is_in_array(array: Array, item) -> bool:
	for i in array.size():
		if array[i] == item:
			return true
	return false

# create a 2D array of size (w, h)
func make_2d_array(w: int, h: int) -> Array:
	var array := []
	for i in range(w):
		array.append([])
		for _j in range(h):
			array[i].append(null)
	return array

# returns the direction of the swipe determined by touch1 and touch2
func touch_direction(touch1: Vector2, touch2: Vector2) -> Vector2:
	var diff := touch2 - touch1
	if abs(diff.x) > abs(diff.y):
		if diff.x > 0:
			return Vector2.RIGHT
		elif diff.x < 0:
			return Vector2.LEFT
	elif abs(diff.x) < abs(diff.y):
		if diff.y > 0:
			return Vector2.DOWN
		elif diff.y:
			return Vector2.UP
	return Vector2.ZERO		

# tells whether a cell is a restricted piece or not (empty, concrete...)
func has_restricted_fill(pos: Vector2) -> bool:
	# check empty spaces
	if is_in_array(empty_spaces, pos):
		return true
	# if is_in_array(concrete_holder.obstacle_pieces, pos):
	# 	return true
	# if is_in_array(slime_holder.obstacle_pieces, pos):
	# 	return true
	return false


# tells whether a piece movement is restricted (locks, ...)
func has_restricted_move(pos: Vector2) -> bool:
	# check locks
	# if is_in_array(lock_holder.obstacle_pieces, pos):	
	# 	return true
	# if is_in_array(slime_holder.obstacle_pieces, pos):	
	# 	return true
	# if is_in_array(concrete_holder.obstacle_pieces, pos):	
	# 	return true
	return false

# returns a position around the column and row that contains a normal piece
func find_normal_neighbour(col, row) -> Vector2:
	var normal_neighbours := []
	if is_in_grid(Vector2(col + 1, row)):
		if grid[col + 1][row] != null:
			normal_neighbours.append(Vector2(col + 1, row))
	if is_in_grid(Vector2(col - 1, row)):
		if grid[col - 1][row] != null:
			normal_neighbours.append(Vector2(col - 1, row))
	if is_in_grid(Vector2(col, row + 1)):
		if grid[col][row + 1] != null:
			normal_neighbours.append(Vector2(col, row + 1))
	if is_in_grid(Vector2(col, row - 1)):
		if grid[col][row - 1] != null:
			normal_neighbours.append(Vector2(col, row - 1))
	if normal_neighbours.size() > 0:
		return normal_neighbours[Player.rng.randi_range(0, normal_neighbours.size()-1)]
	else:
		return Vector2(-1, -1)
