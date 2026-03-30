extends Node2D
var alt: int
var track: int
var fltnum: int
var speed: int = 30
var iscold: bool = false
var goingout: bool = false
var turning: bool = false
var turndirection: int = 0
var cs: String
var bullbear: float
var bullrng: float
var mytgt
@onready var altitude: Label = $altitude
@onready var callsign: Label = $callsign
@onready var symbo: Sprite2D = $Sprite2D
@onready var controller = get_node("/root/game")

var trail: Array[Vector2] = []
var traildots: Array[Sprite2D] = []

var trailtexture: Texture2D
var blank: Texture2D
var actualsymbo: Texture2D

var hotdirection: int = 270
var voice_id: String


func _ready():
	# Resource loading
	trailtexture = load("res://assets/sprites/5xVMJ58-removebg-preview-removebg-preview-blue-dot.png")
	blank = load("res://assets/sprites/radarsymbohost-removebg-emptypng.png")
	actualsymbo = load("res://assets/sprites/5xVMJ58-removebg-preview-removebg-preview-blue-symbo.png")
	
	if controller.northsouth == true:
		hotdirection = 180
		
	track = hotdirection
	symbo.rotation_degrees = track
	
	set_alt()
	
	# TTS Setup
	var voices = DisplayServer.tts_get_voices_for_language("en")
	if voices.size() > 0:
		voice_id = voices[0]

func set_alt():
	alt = randi_range(30, 35)
	altitude.text = str(alt * 10)

func set_cs(name: String, p_fltnum: int):
	self.fltnum = p_fltnum
	cs = name + str(p_fltnum)
	# Logic: First letter + Last letter + flight number (e.g., Viper1 -> VR1)
	callsign.text = name.left(1) + name.right(1) + str(p_fltnum)

func movement(delta: float):
	if turning == true:
		dotheturn(delta)
	var direction = Vector2(sin(deg_to_rad(track)), -cos(deg_to_rad(track)))
	global_position += direction * speed * delta
	
	data_trail()
	place_trail()

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

func music(badguy: String):
	print("%s music %s" % [cs, badguy])
	
	if badguy.contains(controller.bullseyename):
		var slash = badguy.split("/")
		# Logic to break down bearing numbers for "radio" feel
		var bearing_str = slash[0].substr(14)
		if bearing_str.length() >= 3:
			var tts_text = "%s music %s %s %s %s %s %s" % [cs, slash[0].substr(0, 14), bearing_str[0], bearing_str[1], bearing_str[2],bearing_str[3], slash[1]]
			DisplayServer.tts_speak(tts_text, voice_id)
	else:
		DisplayServer.tts_speak("%s music %s" % [cs, badguy], voice_id)

func strobe(badguybear: float):
	var bear_str = str(round(badguybear)).pad_zeros(3)
	print("%s strobe %f" % [cs, badguybear])
	# Speaks digits individually: "1 2 0"
	var tts_msg = "%s strobe %s %s %s" % [cs, bear_str[0], bear_str[1], bear_str[2]]
	DisplayServer.tts_speak(tts_msg, voice_id)

func spike(badguybear: float):
	var bear_str = str(round(badguybear)).pad_zeros(3)
	print("%s spike %f" % [cs, badguybear])
	var tts_msg = "%s spike %s %s %s" % [cs, bear_str[0], bear_str[1], bear_str[2]]
	DisplayServer.tts_speak(tts_msg, voice_id)

func radiocheck(p_fltnum: int):
	DisplayServer.tts_speak(str(p_fltnum), voice_id)
	self.fltnum = p_fltnum

func knockitoff(p_fltnum: int):
	var kio: String = (str(p_fltnum)+ " knock it off") 
	DisplayServer.tts_speak(kio, voice_id)

func checkin(alphacheck: bool):
	if alphacheck == true:
		var fightson = "alpha check same fights on"
		DisplayServer.tts_speak(fightson, voice_id)
	else:
		var msg = "%s %s checking in as fragged request alpha check %s" % [controller.controllercs, cs, controller.bullseyename]
		DisplayServer.tts_speak(msg, voice_id)
func commit():
	if(controller.northsouth == false):
		var commitcall: String = "%s commit west" %[cs.substr(0,cs.length()-1)]
		DisplayServer.tts_speak(commitcall, voice_id)
		print(commitcall)
	else: 
		var commitcall: String = "%s commit south" %[cs.substr(0,cs.length()-1)]
		DisplayServer.tts_speak(commitcall, voice_id)
		print(commitcall)
func reqpic():
	var picreq: String = "%s picture " % [controller.controllercs]
	DisplayServer.tts_speak(picreq, voice_id)
	print(picreq)
func banzai():
	var bazaiflow: String = "%s banzai" %[cs.substr(0,cs.length()-1)]
	DisplayServer.tts_speak(bazaiflow, voice_id)
	print(bazaiflow)
func skate():
	var skateflow: String = "%s skate" %[cs.substr(0,cs.length()-1)]
	DisplayServer.tts_speak(skateflow, voice_id)
	print(skateflow)
func pump():
	var pumpflow: String = "%s pump" %[cs.substr(0,cs.length()-1)]
	DisplayServer.tts_speak(pumpflow, voice_id)
	print(pumpflow)
func targetting(tgt, tgtname, tgtpos, tgtalt):
	var tgtcall: String
	mytgt = tgt
	var bear_str = str(tgtpos[0]).pad_zeros(3)
	if(tgtname == ""):
		tgtcall = "%s targetted group %s %s %s %s %d %s" % [cs, controller.bullseyename, bear_str[0], bear_str[1], bear_str[2], tgtpos[1], tgtalt*1000]
	else:
		tgtcall = "%s targetted %s %s %s %s %s %d %s" % [cs, tgtname, controller.bullseyename, bear_str[0], bear_str[1], bear_str[2], tgtpos[1], tgtalt*1000]
	DisplayServer.tts_speak(tgtcall, voice_id)
	print(tgtcall)
func shooting(tgtname,tgtpos,tgtalt):
	var tgtcall: String
	var bear_str = str(tgtpos[0]).pad_zeros(3)
	if(tgtname == ""):
		tgtcall = "%s fox 3 group %s %s %s %s %d %s" % [cs, controller.bullseyename, bear_str[0], bear_str[1], bear_str[2], tgtpos[1], tgtalt*1000]
	else:
		tgtcall = "%s fox 3 %s %s %s %s %s %d %s" % [cs, tgtname, controller.bullseyename, bear_str[0], bear_str[1], bear_str[2], tgtpos[1], tgtalt*1000]
	DisplayServer.tts_speak(tgtcall, voice_id)
	print(tgtcall)
	
func splashcomm(tgtname):
	var splashcall: String
	if(tgtname == ""):
		splashcall = "%s splash" % [cs]
	else:
		splashcall = "%s splash %s" % [cs, tgtname]
	DisplayServer.tts_speak(splashcall, voice_id)
	print(splashcall)
	
func timeoutcomm(tgtname):
	var timeout: String
	if(tgtname == ""):
		timeout = "%s timeout" % [cs]
	else:
		timeout = "%s timeout %s" % [cs, tgtname]
	DisplayServer.tts_speak(timeout, voice_id)
	print(timeout)
func flow():
	if(controller.northsouth == false):
		var commitcall: String = "%s flow east" %[cs.substr(0,cs.length()-1)]
		DisplayServer.tts_speak(commitcall, voice_id)
		print(commitcall)
	else: 
		var commitcall: String = "%s flow north" %[cs.substr(0,cs.length()-1)]
		DisplayServer.tts_speak(commitcall, voice_id)
		print(commitcall)	
	
func goout():
	if (goingout or iscold) == true:
		return
	goingout = true
	turning = true
	turndirection = (track + 180) % 360
	var outcomm: String = "%s out %s" % [cs,turndirection]
	print(outcomm)
	DisplayServer.tts_speak(outcomm, voice_id)
	pass

func goin():
	#if iscold == false:
	if (goingout or iscold) == false:
		return
	iscold = false
	turning = true
	turndirection = (track + 180) % 360
	goingout = false
	var incomm: String = "%s in %s" % [cs,turndirection]
	print(incomm)
	DisplayServer.tts_speak(incomm, voice_id)

func dotheturn(delta: float):
	var diff = fmod((turndirection - track + 540), 360) - 180
	if abs(diff) <= 30:
		track = turndirection
		turning = false
		if (goingout ==true) and (iscold == false):
			iscold = true
	else:
		track += sign(diff) * 45
		track = fmod(track + 360, 360)
	symbo.rotation_degrees = track
	pass
