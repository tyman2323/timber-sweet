extends Node2D

var alt: int
var track: int 
var id: int = 1 # 1 = h, 2 = f, 3 = b, 4 = bs
var speed: int = 30
var fullname: String
var groupn: String = ""
var arm: String = ""
var contact: String = ""
var targetted: bool = false
var listnum:int 

var bullbear: float
var bullrng: float

@onready var controller = get_node("/root/game")
@onready var getbull = get_node("/root/game/CanvasLayer/cursor")
@onready var altitude: Label = $altitude
@onready var symbo: Sprite2D = $Sprite2D

var trail: Array[Vector2] = []
var traildots: Array[Sprite2D] = []

var eventfinished: bool = false
var events: Array = [] # Using Array as a Queue (pop_front / append)

var trailtexture: Texture2D
var blank: Texture2D
var actualsymbo: Texture2D

var fading: bool = false
var faded: bool = false
var fadedescent: bool = false
var splashed: bool = false
var splashcount: int = 0
var gohot: int = 0
var counter: int = 0
var eventtype = [0, 1, 2, 3, 4, 5, 6, 7, 8] 
#0 = do nothing 1 = willclimb 2 = willdescend  3= willmanuver 4=willmusic  5=willstrobe 6=willspike 7=willspeed 8=willfade
var hotdirection: int = 90

func _ready():
	set_alt()
	
	if controller.northsouth == true:
		hotdirection = 360

	track = hotdirection
	symbo.rotation_degrees = track
	fullname = groupn + arm + contact
	
	trail.append(global_position)
	
	# Resource Loading
	trailtexture = load("res://assets/sprites/radarsymbohost-removebg-preview-dot.png")
	blank = load("res://assets/sprites/radarsymbohost-removebg-emptypng.png")
	actualsymbo = load("res://assets/sprites/radarsymbohost-removebg-preview.png")

	load_event()

func movement(delta: float):
	var direction = Vector2(sin(deg_to_rad(track)), -cos(deg_to_rad(track)))
	global_position += direction * speed * delta
	
	if speed != 30 and randi_range(1, 8) == 1:
		speed = 30
		
	if gohot == 1 and randi_range(1, 6) == 1:
		gohot = 2
	elif gohot == 2:
		going_hot()

	if splashed == true:
		print("splashed is now true")
		doingthesplash()
	if not fading and not faded and not fadedescent:
		data_trail()
		place_trail()
	elif not fading and not faded and fadedescent:
		data_trail()
		place_trail()
		fade()
	elif fading and not faded:
		start_fading()
	elif faded and not fading:
		host_faded()
	

func set_alt():
	alt = randi_range(15, 41)
	altitude.text = str(alt * 10)

func data_trail():
	if trail.size() < 6:
		trail.append(global_position)
	else:
		trail.pop_front()
		trail.append(global_position)

func place_trail():
	for data in trail:
		var dot = Sprite2D.new()
		dot.texture = trailtexture
		dot.global_position = data
		get_parent().add_child(dot)
		
		if traildots.size() < 6:
			traildots.append(dot)
		else:
			var unc = traildots.pop_front()
			if is_instance_valid(unc):
				unc.queue_free()
			traildots.append(dot)

func set_texture(hidesymbo: bool):
	if hidesymbo:
		symbo.texture = blank
	else:
		symbo.texture = actualsymbo

func bullseyepos() -> Array:
	var be_pos = getbull.bullseye
	var my_pos = global_position
	var result = getbull.calculator(be_pos, my_pos)
	bullbear = result[0]
	bullrng = result[1]
	return [bullbear, bullrng]

func climb():
	if randi_range(1, 8) == 1 or alt == 45:
		events.pop_front()
	else:
		alt += 1
		altitude.text = str(alt * 10)

func descend():
	if randi_range(1, 8) == 1 or alt == 15:
		events.pop_front()
	else:
		alt -= 1
		altitude.text = str(alt * 10)

func fade():
	if alt < 15:
		fading = true
		fadedescent = false
		print("It has now faded")
	else:
		alt -= 1
		altitude.text = str(alt * 10)

func start_fading():
	if traildots.size() > 0:
		var unc = traildots.pop_front()
		if is_instance_valid(unc):
			unc.queue_free()
		counter += 1
		print("Counter is ", counter)
		
	if counter == 6:
		visible = false
		fading = false
		faded = true
		counter = 0

func host_faded():
	var res = controller.closestblue(global_position)
	var dist = res[0]
	if randi_range(1, 4) == 1 or dist < 29:
		visible = true
		faded = false

func manuever():
	var prob = randi_range(1, 10)
	gohot = 0
	if prob == 1:
		gohot = 1
		speed = 30
		events.pop_front()
	elif prob < 5:
		track += 15
		speed = 15
		symbo.rotation_degrees = track
	else:
		track -= 15
		speed = 15
		symbo.rotation_degrees = track

func going_hot():
	var anglediff = fposmod(hotdirection - track + 180, 360) - 180
	if abs(anglediff) <= 15:
		track = hotdirection
		symbo.rotation_degrees = track
		speed = 30
		gohot = 0
	else:
		if anglediff > 0:
			track += 15
		else:
			track -= 15
		speed = 15
		symbo.rotation_degrees = track

func load_event():
	var event_total = randi_range(1, 11)
	var placeholder = []
	for x in range(event_total):
		# Storing as a dictionary to mimic the Tuple(int, int)
		placeholder.append({"type": eventtype[randi() % eventtype.size()], "time": randi_range(1, 51)})
	
	# Sort by the 'time' value (equivalent to Item2)
	placeholder.sort_custom(func(a, b): return a.time < b.time)
	
	for c in placeholder:
		events.append(c)

func _on_timer_timeout():
	pass

func setname():
	fullname = groupn + arm + contact
func doingthesplash():
	speed = 7
	events.clear()
	faded = false
	fading = false
	fadedescent = false
	splashcount += 1
	alt -= 1
	altitude.text = str(alt * 10)
	if splashcount > 3:
		for dot in traildots:
			if is_instance_valid(dot):
				dot.get_parent().remove_child(dot)
				dot.queue_free()
		traildots.clear()
		controller.hostile_list.erase(self)  
		queue_free()
