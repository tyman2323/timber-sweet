extends Node2D

var bullseye: Vector2
var bullseyeinfo: Label
var braastuff: Label

var clickstart_world: Vector2
var zclickstart_world: Vector2

var held: bool = false
var zheld: bool = false
var boot: bool = false

func _ready() -> void:
	# Use explicit node typing to avoid variant returns
	var be_node: Sprite2D = get_node("/root/game/be") as Sprite2D
	bullseye = be_node.global_position
	bullseyeinfo = get_node("Sprite2D/bullseyestuff") as Label
	braastuff = get_node("Sprite2D/braastuff") as Label
	braastuff.visible = false

func get_mouse_world_pos() -> Vector2:
	var cam: Camera2D = get_viewport().get_camera_2d()
	return cam.get_global_mouse_position()

func _process(_delta: float) -> void:
	position = get_viewport().get_mouse_position()
	bullseyecalcanddisplay()
	if held:
		braastuff.visible = true
		braacalcanddisplay()
	else:
		braastuff.visible = false
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click:
			zheld = true
			held = false
			zclickstart_world = get_mouse_world_pos()
		elif event.pressed:
			held = true
			clickstart_world = get_mouse_world_pos()
		else:
			held = false
			zheld = false

	if event.is_action_pressed("shift"):
		boot = true
	if event.is_action_released("shift"):
		boot = false

func calculator(origin: Vector2, target: Vector2) -> Array[float]:
	var diff: Vector2 = target - origin
	var angle: float = atan2(diff.x, -diff.y)
	var bearing: float = fposmod(rad_to_deg(angle), 360.0)
	var range: float = round(diff.length() / 20.0)
	return [bearing,range]

func _draw() -> void:
	var cam: Camera2D = get_viewport().get_camera_2d()
	if held:
		var start_screen: Vector2 = cam.get_canvas_transform() * clickstart_world
		draw_line(to_local(start_screen), Vector2.ZERO, Color.GREEN, 2)

	if zheld:
		var start_screen: Vector2 = cam.get_canvas_transform() * zclickstart_world
		var end_screen: Vector2 = get_viewport().get_mouse_position()
		var pixel_dist: float = start_screen.distance_to(end_screen)
		var sf: float = (pixel_dist * 2.5) / sqrt(256.0 + 81.0)
		var w: float = sf * 16.0
		var h: float = sf * 9.0
		var local_start: Vector2 = to_local(start_screen)
		var zoom_rect := Rect2(local_start.x - (w / 2.0), local_start.y - (h / 2.0), w, h)
		draw_rect(zoom_rect, Color.YELLOW, false, 2)

	if boot:
		var screenscale: float = 67.0
		var circ_radius: float = screenscale * cam.zoom.x
		draw_arc(Vector2.ZERO, circ_radius, 0.0, TAU, 64, Color.GREEN, 3, true)

func bullseyecalcanddisplay() -> void:
	var be_node: Sprite2D = get_node("/root/game/be") as Sprite2D
	bullseye = be_node.global_position
	var result = calculator(bullseye, get_mouse_world_pos())
	bullseyeinfo.text = "%03d/%d" % [result[0], result[1]]

func braacalcanddisplay() -> void:
	var result = calculator(clickstart_world, get_mouse_world_pos())
	braastuff.text = "%03d/%d" % [result[0], result[1]]
