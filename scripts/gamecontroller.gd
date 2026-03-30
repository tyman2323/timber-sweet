extends Node2D

var hostiles_scene: PackedScene
var friends_scene: PackedScene
var hostiletot: int #= randi_range(5,5)

var hostile_list: Array = []
var friendlies_list: Array = []

var timeline: Array[bool] = [false,false,false,false,false,false,false,false]
#checkin commit #picture #redec #targetting #shot #goingout #timeout
var timelineevent: int = 0
var tactic:int = 0 #0 = banzai 1 = skate 2 = pump
@onready var voicestuff = $voicestuff
@onready var time_timer: Timer = $refresh
@onready var cursor = $CanvasLayer/cursor

var hidesymbo: bool = false
var blank: Texture2D
var radarsweep: int = 0

var northsouth: bool #= false
var bullseyename: String #= "bullseye"
var controllercs: String #= "demon"
var ftrcs: String #= "viper"
var radiomsg: String = ""
#var td: int = 
func _ready():
	# Load resources
	hostiles_scene = load("res://objects/hostileradarsymbo.tscn")
	friends_scene = load("res://objects/friendlyradarsymbo.tscn")
	blank = load("res://assets/sprites/radarsymbohost-removebg-emptypng.png")
	
	if northsouth:
		spawn_friendlies_ns()
		spawn_badguys_ns()
	else:
		spawn_friendlies()
		spawn_badguys()
		
	
	for i in range(friendlies_list.size()):
		friendlies_list[i].radiocheck(i + 1)
		print("Doing radio checks")
		
	if friendlies_list.size() > 0:
		friendlies_list[0].checkin(false)
		
func _input(event):
	if event.is_action_pressed("period"):
		hidesymbo = !hidesymbo
		symbohider()

func _on_refresh_timeout():
	# Delta is 1 as per your original C# logic
	var delta: float = 1.0
	var tarpy = hostile_list.size()
	print(tarpy)
	if tarpy>0:
		for h in hostile_list:
			h.movement(delta)
			if h.speed > 30 and randi_range(1, 4) == 1:
				h.speed = 30
				print("Now normal speed")
		for h in hostile_list:
			hostile_events(h)
			
	for f in friendlies_list:
		f.movement(delta)
		
	radarsweep += 1
	print("current sweep ", radarsweep)
	print("current timeline event and tactic is  ", timelineevent, tactic)
	if radarsweep%3 == 0:
		if timeline[timelineevent] == false:
			ftrinitiatedtimelineevent()

func spawn_badguys():
	for i in range(hostiletot):
		var inst = hostiles_scene.instantiate()
		add_child(inst)
		hostile_list.append(inst)
		hostile_list[i].listnum = i
		inst.hotdirection = 90
		inst.global_position = Vector2(randf_range(-600, -200), randf_range(0, 400))

func spawn_friendlies_ns():
	var yy = 590
	for i in range(4):
		var inst = friends_scene.instantiate()
		add_child(inst)
		friendlies_list.append(inst)
		inst.global_position = Vector2(yy, -600)
		inst.setcs(ftrcs.to_upper(), i + 1)
		yy += 67

func spawn_badguys_ns():
	for i in range(hostiletot):
		var inst = hostiles_scene.instantiate()
		add_child(inst)
		hostile_list.append(inst)
		hostile_list[i].listnum = i
		inst.global_position = Vector2(randf_range(300, 800), randf_range(1200, 1776))

func spawn_friendlies():
	var yy = 100
	for i in range(4):
		var inst = friends_scene.instantiate()
		add_child(inst)
		friendlies_list.append(inst)
		inst.global_position = Vector2(1776, yy)
		inst.set_cs(ftrcs.to_upper(), i + 1)
		yy += 67

func hotpiss(victim, hostile_node) -> float:
	var result = cursor.calculator(victim.global_position, hostile_node.global_position)
	print(result)
	var bear = degreemoe(result[0])
	return bear

func degreemoe(bullbear: float) -> float:
	var bull_rad = deg_to_rad(bullbear)
	var margin = deg_to_rad(randf_range(-7, 7))
	bull_rad += margin
	return rad_to_deg(bull_rad)

func symbohider():
	for h in hostile_list:
		h.set_texture(hidesymbo)
	for f in friendlies_list:
		f.set_texture(hidesymbo)

func closestblue(hostpos: Vector2) -> Array:
	var dist = 100000000.0
	var ftrindex = 0
	for i in range(friendlies_list.size()):
		var diff = friendlies_list[i].global_position - hostpos
		var tempy = round(diff.length() / 20.0)
		if tempy < dist:
			dist = tempy
			ftrindex = i
	return [dist, ftrindex]

func hostile_events(x):
	if x.events.size() > 0:
		var current_event = x.events[0] # Peek (First element)
		var eventname = current_event.type
		var onsweep = current_event.time
		
		if radarsweep >= onsweep:
			match eventname:
				0:
					print("The event is do nothing, started on sweep ", onsweep)
					x.events.pop_front()
				1:
					print("The event is will climb, started on sweep ", onsweep)
					x.climb()
				2:
					print("The event is will descend, started on sweep ", onsweep)
					x.descend()
				3:
					print("The event is will maneuver, started on sweep ", onsweep)
					x.manuever()
				4:
					var victim_idx = randi() % friendlies_list.size()
					if x.fullname == "":
						var b_pos = x.bullseyepos() # Assuming returns [bear, rng]
						var bull = degreemoe(b_pos[0])
						var bullrng = b_pos[1] + randi_range(-6, 7)
						var nolabel = "Group %s %03d/%d" % [bullseyename, bull, bullrng]
						friendlies_list[victim_idx].music(nolabel)
					else:
						friendlies_list[victim_idx].music(x.fullname)
					x.events.pop_front()
				5:
					var victim_idx = randi() % friendlies_list.size()
					var bear = hotpiss(friendlies_list[victim_idx], x)
					friendlies_list[victim_idx].strobe(bear)
					x.events.pop_front()
				6:
					var victim_idx = randi() % friendlies_list.size()
					var bear = hotpiss(friendlies_list[victim_idx], x)
					friendlies_list[victim_idx].spike(bear)
					x.events.pop_front()
				7:
					print("This event is speed and happened on sweep ", onsweep)
					if randi_range(1, 10) > 7:
						x.speed = randi_range(60, 63)
						print("VERY FAST")
					else:
						print("FAST")
						x.speed = randi_range(40, 56)
					x.events.pop_front()
				8:
					print("This event is fade and happened on sweep ", onsweep)
					x.fadedescent = true
					x.events.pop_front()
func hasalphaceheck(info: String):
	var cursorbull: float = float(info.substr(0,3))
	var cursorng: float = float(info.substr(3))
	var friendpos = cursor.calculator(cursor.bullseye,friendlies_list[0].global_position)
	print(friendpos[0], " /", friendpos[1])
	if ((abs(cursorbull-round(friendpos[0]))<=8) and (abs(cursorng-round(friendpos[1])))<=3):
		friendlies_list[0].checkin(true)
		timeline[0] = true
		if timelineevent == 0:
			timelineevent+=1
	else:
		friendlies_list[0].checkin(false)
	pass

func hascommited():
	if(timelineevent == 1):
		friendlies_list[0].commit()
		timelineevent+=1
	

func hasredec():
	if timelineevent == 3:
		timelineevent+=1
		print(timelineevent)

func ftrinitiatedtimelineevent():
	match timelineevent:
		0:
			friendlies_list[0].checkin(false)
		1:
			var dist = getclosestred(friendlies_list[0])
			print("We are currently ", dist[1], " away from the bad guys")
			if(dist[1]<83):
				friendlies_list[0].commit()
				timelineevent += 1
		2:
			var dist = getclosestred((friendlies_list[0]))
			print("We are currently ", dist[1], " away from the bad guys")
			if(dist[1]<50):
				print("We got no picture so we are just gonna go to targetting now")
				if(hostile_list.size()<=4):
					tactic = 0
					friendlies_list[0].banzai()
					for x in range(friendlies_list.size()):
						friendlies_list[x].goin()
				else:
					friendlies_list[0].skate()
					tactic = 1
				timelineevent += 2
			elif (dist[1]<73):
				friendlies_list[0].reqpic()
		3:
			#reform function to make sure theyre in line
			if tactic == 0 or tactic ==1:
				var result = cursor.calculator(friendlies_list[0].global_position, friendlies_list[2].global_position)
				var dist = result[1]
				if dist>10:
					print("Reform distance between 1 and 3: ", dist)
				else:
					for x in range(friendlies_list.size()):
							friendlies_list[x].goin()
			print("we are now waiting for redec thing")
		4:
			print("WE ARE TARGETTING")
			gettgtinfo()
			timelineevent+=1
		5:
			if tactic==0:
				print("WE ARE SHOOTING")
				for x in range(friendlies_list.size()):
					if(friendlies_list[x].mytgt != null):
						getshotinfo(friendlies_list[x])
				timelineevent=7
			if tactic ==1:
				print("WE ARE SHOOTING")
				for x in range(friendlies_list.size()):
					if(friendlies_list[x].mytgt != null):
						getshotinfo(friendlies_list[x])
				timelineevent = 6
			if tactic ==2:
				print("WE ARE SHOOTING")
				for x in range(friendlies_list.size()):
					if(friendlies_list[x].mytgt != null):
						getshotinfo(friendlies_list[x])
				timelineevent = 6
		6:
			pass
			print("We are husky out")
			for x in range(friendlies_list.size()):
					if(friendlies_list[x].goingout == false):
						friendlies_list[x].goout()
					elif(friendlies_list[x].goingout == true):
						friendlies_list[x].goin()
			timelineevent = 7
			
		7:
			print("timeout comm or splash comm")
			if(tactic == 0):
				for x in range(friendlies_list.size()):
					if(friendlies_list[x].mytgt != null):
						friendlies_list[x].splashcomm(friendlies_list[x].mytgt.fullname)
						friendlies_list[x].mytgt.splashed = true
			if(tactic == 1):
				for x in range(friendlies_list.size()):
					if(friendlies_list[x].mytgt != null):
						friendlies_list[x].timeoutcomm(friendlies_list[x].mytgt.fullname)
						friendlies_list[x].mytgt.splashed = true
				friendlies_list[0].flow()
			if(tactic == 2):
				for x in range(friendlies_list.size()):
					if(friendlies_list[x].mytgt != null):
						friendlies_list[x].timeoutcomm(friendlies_list[x].mytgt.fullname)
						friendlies_list[x].mytgt.splashed = true
			timelineevent = 2
			friendlies_list[0].reqpic()
				
func gettgtinfo():
	for x in range(friendlies_list.size()):
		var mytgt
		if friendlies_list[x].goingout == false:
			var temp = getclosesttgtred(friendlies_list[x])
			if(getclosestred(friendlies_list[x])[1]-temp[1]<=10000000):#td goes here
				mytgt = temp[0]
				mytgt.targetted = true
				print(friendlies_list[x].cs + " Will target: " + mytgt.fullname)
				var tgtname = mytgt.fullname
				var tgtpos = mytgt.bullseyepos()
				var tgtalt = mytgt.alt
				friendlies_list[x].targetting(mytgt,tgtname,tgtpos,tgtalt)
func getshotinfo(shooter):
	var tgtname = shooter.mytgt.fullname
	var tgtpos = shooter.mytgt.bullseyepos()
	var tgtalt = shooter.mytgt.alt
	shooter.shooting(tgtname,tgtpos,tgtalt)
	pass
func getclosestred(y) -> Array:
	var closestred: Array = [null, 1000000.0] 
	for x in range(hostile_list.size()):
		var result: Array = cursor.calculator(y.global_position, hostile_list[x].global_position)
		var current_dist = result[1]
		if current_dist < closestred[1]:
			closestred[1] = current_dist
			closestred[0] = hostile_list[x]
	return closestred
	
func getclosesttgtred(y) -> Array:
	var target: Array = [null, 1000000.0] 
	for x in range(hostile_list.size()):
		var result: Array = cursor.calculator(y.global_position, hostile_list[x].global_position)
		var current_dist = result[1]
		if (current_dist < target[1]) and (hostile_list[x].targetted == false):
			target[1] = current_dist
			target[0] = hostile_list[x]
	return target

func bullseyetovector2(bearing: float, range_val: float):
	var distance = range_val * 20.0
	var angle_rad = deg_to_rad(bearing)
	var x = sin(angle_rad) * distance
	var y = -cos(angle_rad) * distance
	return Vector2(x, y)
	
func getclosestredsingrp(goodbear,goodrng,howmany):
	var v2 = bullseyetovector2(goodbear,goodrng)
	var baddies = []
	for x in range(hostile_list.size()):
		var result: Array = cursor.calculator(v2,hostile_list[x].global_position)
		var dist = result[1]
		baddies.append([hostile_list[x],dist])
	baddies.sort_custom(func(a, b): return a[1] < b[1])
	var baddiesfin = []
	for x in range(howmany):
		baddiesfin.append(baddies[x])
	#print(baddiesfin)
	return baddiesfin

func singlegroup(bear: int, rng: int, contacts: int):
	var grpcontacts = getclosestredsingrp(bear,rng,contacts) 
	for x in range(grpcontacts.size()):
		grpcontacts[x][0].groupn = "single group"
		grpcontacts[x][0].setname()
	for x in range(grpcontacts.size()):
		print("I AM ",grpcontacts[x][0].fullname)
	if(hostile_list.size()<=4):
		tactic = 0
		friendlies_list[0].banzai()
		for x in range(friendlies_list.size()):
			friendlies_list[x].goin()
	else:
		friendlies_list[0].skate()
		tactic = 1
func twogrpazimuth(azimuth: Array, wide:int):
	if(wide<10):
		var totalcontacts: int = 0
		for x in range(azimuth.size()):
			totalcontacts += azimuth[x][1][azimuth[x][1].size()-1]
		var gb = azimuth[0][0]
		var gn = azimuth[1][0]
		var name
		var grpcontacts = getclosestredsingrp(azimuth[0][1][0],azimuth[0][1][1],totalcontacts)
		#print(totalcontacts, grpcontacts.size())
		for x in range(grpcontacts.size()):
			if((x+1<=(azimuth[0][1][azimuth[0][1].size()-1]))):

				match gb:
					"s", "south":
						name = "south group"
					"n", "north":
						name = "north group"
					"e", "east":
						name = "east group"
					"w", "west":
						name = "west group"
				grpcontacts[x][0].groupn = name
				grpcontacts[x][0].setname()
			else:
				match gn:
					"s", "south":
						name = "south group"
					"n", "north":
						name = "north group"
					"e", "east":
						name = "east group"
					"w", "west":
						name = "west group"
				grpcontacts[x][0].groupn = name
				grpcontacts[x][0].setname()
			for y in range(grpcontacts.size()):
				print("I AM ",grpcontacts[y][0].fullname)
	else:
		pass#treat it as two single groups
		for x in range(azimuth.size()):
			var grpcontacts = getclosestredsingrp(azimuth[x][1][0],azimuth[x][1][1],azimuth[x][1][2])
			var gn = azimuth[x][0]
			var name
			match gn:
					"s", "south":
						name = "south group"
					"n", "north":
						name = "north group"
					"e", "east":
						name = "east group"
					"w", "west":
						name = "west group"
			for y in range(grpcontacts.size()):
				grpcontacts[y][0].groupn = name
				grpcontacts[y][0].setname()
			for y in range(grpcontacts.size()):
				print("I AM ",grpcontacts[y][0].fullname)
	if(hostile_list.size()<=4):
		friendlies_list[0].banzai()
		#for x in range(friendlies_list.size()):
			#friendlies_list[x].goin()
		tactic = 0
	else:
		friendlies_list[0].skate()
		tactic = 1
func threegroupchampagne(champ: Array, wide: int, deep: int):
	var totalcontacts: int = 0
	for x in range(champ.size()):
		totalcontacts += champ[x][1][champ[x][1].size()-1]
	var grpcontacts = ""
	var leadcontact = 0
	if(wide<10):
		grpcontacts =  getclosestredsingrp(champ[0][1][0], champ[0][1][1], totalcontacts)
		leadcontact = champ[0][1][2] + champ[1][1][0]
		for x in range(grpcontacts.size()):
			if grpcontacts[x][0] == null:
				pass
			var groupname 
			if x <leadcontact:
				var gn: String = champ[x][0]
				match gn[0]:
					"s":
						gn = "south lead group"
					"n":
						gn = "north lead group"
					"e":
						gn = "east lead group"
					"w":
						gn = "west lead group"
				groupname = gn
			else:
				groupname = "trail group"
			grpcontacts[x][0].groupn = groupname
			grpcontacts[x][0].setname()
			print("I AM ", grpcontacts[x][0].fullname)
	else:
		leadcontact = champ[0][1][2] + champ[1][1][2]
		for x in range(2):
			grpcontacts = getclosestredsingrp(champ[x][1][0],champ[x][1][1],champ[x][1][2])
			var gn: String = champ[x][0]
			var name
			match gn[0]:
					"s":
						name = "south lead group"
					"n":
						name = "north lead group"
					"e":
						name = "east lead group"
					"w":
						name = "west lead group"
			for y in range(grpcontacts.size()):
				grpcontacts[y][0].groupn = name
				grpcontacts[y][0].setname()
			for y in range(grpcontacts.size()):
				print("I AM ",grpcontacts[y][0].fullname)
		var tgrpcontacts = getclosestredsingrp(champ[1][1][0],champ[1][1][1]+deep,champ[2][1][0])
		for z in range(grpcontacts.size()):
				tgrpcontacts[z][0].groupn = "trail group"
				tgrpcontacts[z][0].setname()
		for z in range(tgrpcontacts.size()):
			print("I AM ",tgrpcontacts[z][0].fullname)
	if(hostile_list.size()<=4):
		friendlies_list[0].banzai()
		for x in range(friendlies_list.size()):
			friendlies_list[x].goin()
		tactic = 0
	else:
		friendlies_list[0].skate()
		tactic = 1
func threegrpvic(vic: Array, wide: int, deep: int):
	var leadcontacts = getclosestredsingrp(vic[0][1][0], vic[0][1][1], vic[0][1][2])
	for x in leadcontacts.size():
		leadcontacts[x][0].groupn = "lead group"
		leadcontacts[x][0].setname()
	var trailrng: int = vic[0][1][1] + deep
	var offset: int = 0
	offset = round((float(wide) / float(vic[0][1][1])) * 60.0) / 2.0
	var trailonecontacts
	var trailtwocontacts
	var trailonename
	var trailtwoname
	for x in range(1,3):
		var gn: String = vic[x][0]
		match gn[0]:
					"s":
						trailtwoname = "south trail group"
						var trailonebear: int = vic[0][1][1] - offset
						trailtwocontacts = getclosestredsingrp(trailonebear, vic[0][1][1], vic[1][1][0])
					"n":
						trailonename = "north trail group"
						var trailonebear: int = vic[0][1][1] + offset
						trailonecontacts = getclosestredsingrp(trailonebear, vic[0][1][1], vic[1][1][0])
					"e":
						trailtwoname = "east trail group"
						var trailonebear: int = vic[0][1][1] - offset
						trailtwocontacts = getclosestredsingrp(trailonebear, vic[0][1][1], vic[1][1][0])
					"w":
						trailonename = "west trail group"
						var trailonebear: int = vic[0][1][1] + offset
						trailonecontacts = getclosestredsingrp(trailonebear, vic[0][1][1], vic[1][1][0])
	for x in trailonecontacts.size():
		trailonecontacts[x][0].groupn = trailonename
		trailonecontacts[x][0].setname()
		print("I AM ",trailonecontacts[x][0].fullname)
	for x in trailtwocontacts.size():
		trailtwocontacts[x][0].groupn = trailtwoname
		trailtwocontacts[x][0].setname()
		print("I AM ",trailtwocontacts[x][0].fullname)
	if(hostile_list.size()<=4):
		friendlies_list[0].banzai()
		tactic = 0
		for x in range(friendlies_list.size()):
			friendlies_list[x].goin()
	else:
		friendlies_list[0].pump()
		tactic = 2
		grinder()
func threegrpwall(wall: Array):
	var totalcontacts: int = 0
	for x in range(wall.size()):
		totalcontacts += wall[x][1][wall[x][1].size()-1]
	var grpcontacts = getclosestredsingrp(wall[0][1][0], wall[0][1][1], totalcontacts)
	var z: int = 0
	for x in range(wall.size()):
		var gn: String = wall[x][0]
		for y in range(wall[x][1][wall[x][1].size()-1]):
			match gn:
				"n": 
					gn = "north"
				"s":
					gn = "south"
				"e":
					gn = "east"
				"w":
					gn = "west"
				pass
			grpcontacts[z][0].groupn = gn + " group"
			grpcontacts[z][0].setname()
			print("I AM ",grpcontacts[z][0].fullname)
			z+=1
	if(hostile_list.size()<=4):
		friendlies_list[0].banzai()
		tactic = 0
		for x in range(friendlies_list.size()):
			friendlies_list[x].goin()
	else:
		tactic = 1
		friendlies_list[0].skate()
func fourgrpwall(wall: Array):
	var totalcontacts: int = 0
	for x in range(wall.size()):
		totalcontacts += wall[x][1][wall[x][1].size()-1]
	var grpcontacts = getclosestredsingrp(wall[0][1][0], wall[0][1][1], totalcontacts)
	var z: int = 0
	var nameorder: Array
	var fg: String = wall[0][0]
	match fg:
		"n":
			nameorder = ["north group", "north middle group", "south middle group", "south group"]
		"s":
			nameorder = ["south group", "south middle group", "north middle group", "north group"]
		"e":
			nameorder = ["east group", "east middle group", "west middle group", "west group"]
		"w":
			nameorder = ["west group", "west middle group", "east middle group", "east group"]
	for x in range(wall.size()):
		var gn: String = wall[x][0]
		for y in range(wall[x][1][wall[x][1].size()-1]):
			grpcontacts[z][0].groupn = nameorder[x]
			grpcontacts[z][0].setname()
			print("I AM ",grpcontacts[z][0].fullname)
			z+=1
	if(hostile_list.size()<=4):
		friendlies_list[0].banzai()
		tactic = 0
		for x in range(friendlies_list.size()):
			friendlies_list[x].goin()
	else:
		tactic = 1
		friendlies_list[0].skate()
	timelineevent+=1
func fivegrpwall(wall: Array):
	var totalcontacts: int = 0
	for x in range(wall.size()):
		totalcontacts += wall[x][1][wall[x][1].size()-1]
	var grpcontacts = getclosestredsingrp(wall[0][1][0], wall[0][1][1], totalcontacts)
	var z: int = 0
	var nameorder: Array
	var fg: String = wall[0][0]
	match fg:
		"n":
			nameorder = ["north group", "north middle group","middle group", "south middle group", "south group"]
		"s":
			nameorder = ["south group", "south middle group","middle group", "north middle group", "north group"]
		"e":
			nameorder = ["east group", "east middle group","middle group", "west middle group", "west group"]
		"w":
			nameorder = ["west group", "west middle group","middle group", "east middle group", "east group"]
	for x in range(wall.size()):
		var gn: String = wall[x][0]
		for y in range(wall[x][1][wall[x][1].size()-1]):
			grpcontacts[z][0].groupn = nameorder[x]
			grpcontacts[z][0].setname()
			print("I AM ",grpcontacts[z][0].fullname)
			z+=1
	friendlies_list[0].skate()
	tactic = 1
func ladder(ladder: Array):
	var totalcontacts: int = 0
	for x in range(ladder.size()):
		totalcontacts += ladder[x][1][ladder[x][1].size()-1]
	var grpcontacts = getclosestredsingrp(ladder[0][1][0], ladder[0][1][1], totalcontacts)
	var z: int = 0
	for x in range(ladder.size()):
		var gn: String = ladder[x][0]
		for y in range(ladder[x][1][ladder[x][1].size()-1]):
			grpcontacts[z][0].groupn = gn + " group"
			grpcontacts[z][0].setname()
			print("I AM ",grpcontacts[z][0].fullname)
			z+=1
	if(hostile_list.size()<=4):
		friendlies_list[0].banzai()
		tactic = 0
		for x in range(friendlies_list.size()):
			friendlies_list[x].goin()
	else:
		friendlies_list[0].pump()
		tactic = 2
		grinder()
func grinder():
	if(friendlies_list[0].iscold == false) and (friendlies_list[2].iscold == false ):
		friendlies_list[0].goout()
		friendlies_list[1].goout()
	elif(friendlies_list[0].iscold == true) and (friendlies_list[2].iscold == false ):
		friendlies_list[2].goout()
		friendlies_list[3].goout()
		friendlies_list[0].goin()
		friendlies_list[1].goin()
	elif(friendlies_list[0].iscold == false) and (friendlies_list[2].iscold == true ):
		friendlies_list[0].goout()
		friendlies_list[1].goout()
		friendlies_list[2].goin()
		friendlies_list[3].goin()
	pass
func qctargeting(shooter, tgtname):
	match tgtname:
		"n":
			tgtname = "north"
		"s":
			tgtname = "south"
		"e":
			tgtname = "east"
		"w":
			tgtname = "west"
		"n lead":
			tgtname = "north lead"
		"s lead":
			tgtname = "south lead"
		"e lead":
			tgtname = "east lead"
		"w lead":
			tgtname = "west lead"
		"n trail":
			tgtname = "north trail"
		"s trail":
			tgtname = "south trail"
		"e trail":
			tgtname = "east trail"
		"w trail":
			tgtname = "west trail"
	var tgt = shooter.mytgt
	tgt.groupn = tgtname + " group"
	tgt.setname()
	pass
func knockitoff():
	for x in range(friendlies_list.size()):
		friendlies_list[x].knockitoff(x+1)
	#var title = load("res://scenes/titlescreen.tscn").instantiate()
	#get_tree().root.add_child(title)
	#get_tree().current_scene.queue_free()
	pass
