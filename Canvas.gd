extends TextureRect

################################################################################
# https://godotengine.org/qa/3804/how-to-edit-an-image-pixels

var rng = RandomNumberGenerator.new()

var canvas : Image = null
var canvasTexture : ImageTexture = null

var field := PoolIntArray()


################################################################################
func _ready() -> void:
	rng.randomize()
	var screen_size := get_viewport().size
	self.rect_size = Vector2(80, 45)

	r_pentomino()
	
	self.rect_scale = screen_size / self.rect_size

	canvas = Image.new()
	canvas.create(int(self.rect_size.x), int(self.rect_size.y), false, Image.FORMAT_RGB8)
	canvas.fill(Color8(0,0,0))

	canvasTexture = ImageTexture.new()
	canvasTexture.create_from_image(canvas, Image.INTERPOLATE_NEAREST)
	self.texture = canvasTexture
	
	var _sc = get_tree().get_root().connect("size_changed", self, "resize_canvas")


################################################################################
var timer : float = 0.0
var fc : int = 0 #frame_counter
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
	
	timer = timer + delta
	if timer > frame_time:
		#canvas.fill(Color8(0, 0, 0))

		canvas.lock()
		game_of_life()
		#random_walker()
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
	var index : int = int(pos.x) + int(pos.y) * int(self.rect_size.x)
	return index;


################################################################################
func wrap(to_wrap : Vector2) -> Vector2:
	var out := to_wrap
	if out.x < 0:
		out.x = int(self.rect_size.x - 1)
	if out.x >= self.rect_size.x:
		out.x = 0
	if out.y < 0:
		out.y = int(self.rect_size.y - 1)
	if out.y >= self.rect_size.y:
		out.y = 0
	return out


################################################################################
var walker_pos := Vector2(self.rect_size.x / 2, self.rect_size.y / 2)
func random_walker() -> void:
	# clear previous pixel
	# canvas.set_pixel(int(walker_pos.x), int(walker_pos.y), Color8(0, 0, 0))
	
	# set next pixel
	walker_pos.x = walker_pos.x + rng.randi_range(-1,1)
	walker_pos.y = walker_pos.y + rng.randi_range(-1,1)
	walker_pos = wrap(walker_pos)

	canvas.set_pixel(int(walker_pos.x), int(walker_pos.y), Color8(255, 255, 255))


################################################################################
func game_of_life() -> void:
	var next := PoolIntArray()
	for p in (self.rect_size.x * self.rect_size.y):
		next.append(0)

	for y in self.rect_size.y:
		for x in self.rect_size.x:
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
				var p := Vector2(pos.x + x, pos.y + y)
				var f := field[index_from_pos(wrap(p))]
				nc = nc + f
	return nc


################################################################################
func r_pentomino() -> void:
	field = PoolIntArray()
	for p in (self.rect_size.x * self.rect_size.y):
		field.append(0)

	var pos := Vector2(self.rect_size.x / 2, self.rect_size.y / 2)
	field[index_from_pos(pos)-1] = 1
	field[index_from_pos(pos)+0] = 1
	field[index_from_pos(pos)+1] = 1
	pos.y = pos.y - 1
	field[index_from_pos(pos)] = 1
	pos.y = pos.y + 2
	pos.x = pos.x + 1
	field[index_from_pos(pos)] = 1


################################################################################
