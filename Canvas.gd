extends TextureRect

################################################################################
# https://godotengine.org/qa/3804/how-to-edit-an-image-pixels

var rng = RandomNumberGenerator.new()

var canvas : Image = null
var canvasTexture : ImageTexture = null

var field := PoolIntArray()

var cols : int = 80
var rows : int = 45

################################################################################
func _ready() -> void:
	rng.randomize()

	var screen_size := get_viewport().size
	self.rect_size = Vector2(cols, rows)
	self.rect_scale = screen_size / self.rect_size

	canvas = Image.new()
	canvas.create(cols, rows, false, Image.FORMAT_RGB8)
	canvas.fill(Color8(0,0,0))

	canvasTexture = ImageTexture.new()
	canvasTexture.create_from_image(canvas, Image.INTERPOLATE_NEAREST)
	self.texture = canvasTexture
	
	var _sc = get_tree().get_root().connect("size_changed", self, "resize_canvas")

	r_pentomino()


################################################################################
var timer : float = 0.0
var fc : int = 0 # frame_counter
var ft : float = 0.0 # frame_timer
var frame_time : float = 0.0666 # 15 fps
func _process(delta : float) -> void:
	# print framerate
	ft = ft + delta
	fc = fc + 1
	if ft >= 5.0:
		print("render: ", int(fc / 5.0), " update: ", int(1.0 / frame_time), " fps")
		fc = 0
		ft = 0.0

	# update
	timer = timer + delta
	if timer > frame_time:
		canvas.lock()
		game_of_life()
		random_walker()
		canvas.unlock()
		
		canvasTexture.set_data(canvas)
		self.texture = canvasTexture
		
		timer = 0.0


################################################################################
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	
	if event.as_text() == "Space":
		r_pentomino()

	if event is InputEventMouseButton:
		var pos = event.position / self.rect_scale
		print("mouse button event at (", int(pos.x), ", ", int(pos.y), ")")


################################################################################
func resize_canvas() -> void:
	var screen_size := get_viewport().size
	self.rect_scale = screen_size / self.rect_size
	print("Resizing: ", screen_size)


################################################################################
func index_from_pos(pos : Vector2) -> int:
	var index : int = int(pos.x) + int(pos.y) * cols
	return index;


################################################################################
func wrap(to_wrap : Vector2) -> Vector2:
	var out := to_wrap
	if out.x < 0:
		out.x = cols - 1
	if out.x >= cols:
		out.x = 0
	if out.y < 0:
		out.y = rows - 1
	if out.y >= rows:
		out.y = 0
	return out


################################################################################
var walker_pos := Vector2(cols / 5.0, rows / 2.0)
func random_walker() -> void:
	# clear previous pixel
	canvas.set_pixel(int(walker_pos.x), int(walker_pos.y), Color8(0, 0, 0))
	
	# set next pixel
	walker_pos.x = walker_pos.x + rng.randi_range(-1,1)
	walker_pos.y = walker_pos.y + rng.randi_range(-1,1)
	walker_pos = wrap(walker_pos)

	# wake up a pixel in the field
	var index := index_from_pos(walker_pos)
	field[index] = 1

	canvas.set_pixel(int(walker_pos.x), int(walker_pos.y), Color8(255, 0, 0))


################################################################################
func game_of_life() -> void:
	var next := PoolIntArray()
	for p in (cols * rows):
		next.append(0)

	for y in rows:
		for x in cols:
			var nc := count_neighbors(Vector2(x, y))
			var index := index_from_pos(Vector2(x, y))

			if (nc == 2 || nc == 3) && field[index] == 1:
				next[index] = 1
			if nc < 2:
				next[index] = 0
			if nc > 3:
				next[index] = 0
			if nc == 3:
				next[index] = 1

			# draw field
			if field[index_from_pos(Vector2(x, y))] == 1:
				canvas.set_pixel(int(x), int(y), Color8(255, 255, 255))
			else:
				canvas.set_pixel(int(x), int(y), Color8(0, 0, 0))

	field = next


################################################################################
func count_neighbors(pos : Vector2) -> int:
	var nc : int = 0
	
	for y in range(-1,2):
		for x in range(-1,2):
			if x == 0 && y == 0:
				pass # this is us
			else:
				var neighbor := Vector2(pos.x + x, pos.y + y)
				var index := index_from_pos(wrap(neighbor))
				var value := field[index] # 0 or 1
				nc = nc + value
	return nc


################################################################################
func r_pentomino() -> void:
	field = PoolIntArray()
	for p in (cols * rows):
		field.append(0)

	var pos := Vector2(cols / 2.0, rows / 2.0)
	field[index_from_pos(pos)-1] = 1
	field[index_from_pos(pos)+0] = 1
	field[index_from_pos(pos)+1] = 1
	pos.y = pos.y - 1
	field[index_from_pos(pos)] = 1
	pos.y = pos.y + 2
	pos.x = pos.x + 1
	field[index_from_pos(pos)] = 1
