extends Camera2D

var zheld: bool = false
var zclickstart_global: Vector2

# History stack for previous zoom levels
var zoom_stack: Array = []

# Array of 10 presets, initialized to current zoom/position in _ready
var psz: Array = []

@onready var timey: Timer = $Timer
var psz_save: bool = false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	# Initialize presets with current view
	for i in range(10):
		psz.append({"zoom": zoom, "position": global_position})
	
	zoom_stack.append({"zoom": zoom, "position": global_position})

func _input(event):
	# Handle Box Zoom
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click:
			zheld = true
			zclickstart_global = get_global_mouse_position()
		elif not event.pressed and zheld:
			camzoom()
			zheld = false

	# Handle History Back
	if event.is_action_pressed("backspace") or event.is_action_pressed("tilda"):
		prevzoom()

	# Handle Mouse Wheel Zoom
	if event.is_action("wheelup"):
		zoom += Vector2(0.1, 0.1)
	if event.is_action("wheeldown"):
		zoom -= Vector2(0.1, 0.1)
	
	# Clamp zoom to prevent flipping or getting stuck
	zoom = zoom.clamp(Vector2(0.1, 0.1), Vector2(10.0, 10.0))

	handle_presets(event)
	handle_movement()

func camzoom():
	var zclickend_world = get_global_mouse_position()
	var world_dist = zclickstart_global.distance_to(zclickend_world)

	if world_dist < 2:
		return

	# 1. Store history
	zoom_stack.append({"zoom": zoom, "position": global_position})

	# 2. Calculate new zoom factor
	var screen_size = get_viewport_rect().size
	var desired_world_width = world_dist * 2.0
	var zoom_factor = screen_size.x / desired_world_width

	zoom = Vector2(zoom_factor, zoom_factor)

	# 3. Center camera (Note: fixed logic from C# to use start/end midpoint)
	global_position = zclickstart_global

func prevzoom():
	if zoom_stack.size() > 0:
		var last = zoom_stack.pop_back()
		zoom = last.zoom
		global_position = last.position

func handle_presets(event):
	for i in range(10):
		var action_name = "psz" + str(i)
		if event.is_action_pressed(action_name):
			timey.start()
		
		if event.is_action_released(action_name):
			if psz_save:
				psz[i] = {"zoom": zoom, "position": global_position}
			else:
				zoom = psz[i].zoom
				global_position = psz[i].position
			
			timey.stop()
			psz_save = false

func handle_movement():
	var dir = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	)
	global_position += dir * 20

# Connect this from the Timer node's 'timeout' signal in the editor
func _on_timer_timeout():
	psz_save = true
