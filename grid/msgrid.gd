extends GridContainer

enum {CONTINUE, VICTORY, LOSS}
const TileScn = preload("res://tile.tscn")
const tileicon = {
	"hidden": preload("res://tiles/hidden.png"),
	"flag": preload("res://tiles/flag.png"),
	"empty": preload("res://tiles/empty.png"),
	"1": preload("res://tiles/one.png"),
	"2": preload("res://tiles/two.png"),
	"3": preload("res://tiles/three.png"),
	"4": preload("res://tiles/four.png"),
	"5": preload("res://tiles/five.png"),
	"6": preload("res://tiles/six.png"),
	"7": preload("res://tiles/seven.png"),
	"8": preload("res://tiles/eight.png"),
	"mine": preload("res://tiles/mine.png"),
	"minehit": preload("res://tiles/minehit.png"),
	"omega": preload("res://tiles/omega_mine.png")
}

@export var width = 10
@export var height = 10
@export var mines = 10

var game_status = CONTINUE

var mine_ids = [] # Array containing all mine tile IDs
var tile_array = [] # Array containing all non-mine tile IDs

var tiles_left = 0
var tilecount = 0

func _ready():
	columns = width
	tilecount = width * height
	
	if mines > tilecount - 10:
		push_error("Reduce the number of mines.")
		mines = tilecount - 10
	
	tiles_left = tilecount - mines
	
	for n in tilecount:
		var tile = TileScn.instantiate()
		tile.id = n
		var x = n % width
		var y = n / width
		tile.tile_position = Vector2i(x,y)
		tile_array.push_back(n)
		add_child(tile)
	
	for _n in mines:
		var rand_idx = randi_range(0,tile_array.size()-1)
		var tile_id = tile_array[rand_idx]
		var target = get_child(tile_id)
		target.mine = true
		tile_array.remove_at(rand_idx) 
		mine_ids.push_back(tile_id)
	
	var omega_index = randi_range(0, mine_ids.size() - 1)
	var omega_tile_id = mine_ids[omega_index]
	var omega_tile = get_child(omega_tile_id)
	
	#omega_tile.mine = false
	omega_tile.omega = true
	omega_tile.texture_normal = tileicon["omega"]
	# mine_ids.erase(omega_tile_id)

var selected_tile : TextureButton

func tile_down(id):
	if game_status: return # If game hasn't started, return
	var tile = get_child(id)
	if !tile.tilehidden: return
	tile.texture_normal = tileicon["empty"]

func tile_up(id):
	if game_status: return
	var tile = get_child(id)
	if !tile.tilehidden: return
	tile.texture_normal = tileicon["hidden"]

func tile_pressed(id):
	if game_status: return 
	var tile = get_child(id)
	if tile.flag: return 
	if !tile.tilehidden: return
	var result = reveal(tile)
	if result:
		game_over(result)

func tile_flag(id):
	if game_status: return
	var tile = get_child(id)
	if !tile.tilehidden: return
	tile.flag = !tile.flag
	if tile.flag:
		tile.texture_normal = tileicon["flag"]
	else:
		tile.texture_normal = tileicon["hidden"]

func tile_chord(id):
	var tile = get_child(id)
	if tile.tilehidden: return
	var flag_count = 0
	for xd in 3:
		for yd in 3:
			if yd == 1 and xd == 1: continue 
			var x = xd-1 + tile.tile_position.x
			var y = yd-1 + tile.tile_position.y
			if x < 0 or x > width-1: continue
			if y < 0 or y > height-1: continue
			var target = get_child(vector_to_id(Vector2i(x,y)))
			if !target.tilehidden: continue
			if target.flag: flag_count += 1
	
	if tile.near == flag_count:
		for xd in 3:
			for yd in 3:
				if yd == 1 and xd == 1: continue
				var x = xd-1 + tile.tile_position.x 
				var y = yd-1 + tile.tile_position.y
				if x < 0 or x > width-1: continue
				if y < 0 or y > height-1: continue
				var target = get_child(vector_to_id(Vector2i(x,y)))
				if !target.tilehidden: continue
				var result = reveal(target)
				if result:
					game_over(result)
	

var first_click = true
func reveal(tile):
	if game_status: return
	if !tile.tilehidden: return
	if tile.flag: return
	tile.mouse_default_cursor_shape = CURSOR_ARROW
	
	# Ensure the first click isn't a bomb
	if first_click:
		clear_bombs(tile)
		get_parent().starting_time = Time.get_ticks_msec()
		
				
	tiles_left -= 1
	
	tile.tilehidden = false
	
	var mine_count = 0
	if !first_click:
		if tile.mine:
			get_parent().frozen_time = Time.get_ticks_msec() - get_parent().starting_time
			tile.texture_normal = tileicon["minehit"]
			for n in mine_ids:
				if n == tile.id: continue
				get_child(n).texture_normal = tileicon["mine"]
			return LOSS
		
		# Check adjacent cells for mines
		for xd in 3: 
			for yd in 3:
				if yd == 1 and xd == 1: continue 
				var x = xd-1 + tile.tile_position.x 
				var y = yd-1 + tile.tile_position.y
				if x < 0 or x > width-1: continue
				if y < 0 or y > height-1: continue
				var target = get_child(vector_to_id(Vector2i(x,y)))
				if !target.tilehidden: continue
				if target.mine: mine_count += 1
	
	first_click = false
	
	if mine_count:
		tile.texture_normal = tileicon[str(mine_count)]
		tile.near = mine_count
	else:
		tile.texture_normal = tileicon["empty"]
		for xd in 3:
			for yd in 3:
				if yd == 1 and xd == 1: continue 
				var x = xd-1 + tile.tile_position.x
				var y = yd-1 + tile.tile_position.y
				if x < 0 or x > width-1: continue
				if y < 0 or y > height-1: continue
				var target = get_child(vector_to_id(Vector2i(x,y)))
				if !target.tilehidden: continue
				reveal(target)
	
	if tiles_left == 0:
		get_parent().frozen_time = Time.get_ticks_msec() - get_parent().starting_time
		return VICTORY
	
	return CONTINUE

func game_over(condition):
	game_status = condition
	for n in tilecount: get_child(n).mouse_default_cursor_shape = CURSOR_ARROW
	if condition == LOSS:
		get_parent().get_node("GameStat").text = "You lost."
	elif condition == VICTORY:
		get_parent().get_node("GameStat").text = "You won!"
	get_parent().get_node("GameStat").show()

func vector_to_id(vector : Vector2i):
	return vector.y * width + vector.x

func clear_bombs(tile):
	var mine_count = 0
	
	# Erase bombs to create a playable starting area
	for xd in 3:
		for yd in 3:
			var x = xd-1 + tile.tile_position.x 
			var y = yd-1 + tile.tile_position.y
			if x < 0 or x > width-1: continue
			if y < 0 or y > height-1: continue
			var target = get_child(vector_to_id(Vector2i(x,y)))
			tile_array.erase(target.id)
			if !target.tilehidden: continue
			if target.mine:
				mine_ids.erase(target.id)
				target.mine = false
				mine_count += 1
	
	# Replace all of the mines that were erased
	for n in mine_count: 
		var rand_idx = randi_range(0,tile_array.size()-1)
		var tile_id = tile_array[rand_idx]
		var target = get_child(tile_id)
		
		target.mine = true
		tile_array.remove_at(rand_idx) 
		mine_ids.push_back(tile_id)
