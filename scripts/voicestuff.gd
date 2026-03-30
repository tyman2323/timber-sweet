extends Node

var recognition
var callback = JavaScriptBridge.create_callback(_on_speech_result)
var transmit: bool = false
var regex
@onready var controller = get_parent()
@onready var textbox = $TextEdit

func _ready():
	regex = RegEx.new()
	if OS.has_feature("web"):
		var window = JavaScriptBridge.get_interface("window")
		# Determine the correct prefix for the browser
		var speech = "SpeechRecognition"
		if not window.SpeechRecognition and window.webkitSpeechRecognition:
			speech = "webkitSpeechRecognition"
		
		recognition = JavaScriptBridge.create_object(speech)
		if recognition:
			recognition.continuous = true
			recognition.interimResults = false
			recognition.lang = "en-US"
			recognition.onresult = callback
		else:
			print("Speech Recognition not supported in this browser.")

func _input(event) -> void:
	if event.is_action_pressed("radioptt"):
		if DisplayServer.tts_is_speaking():
			# Logic for "Breaking" or priority interrupts could go here
			print("You are being talked over.")
			textbox.text = "You are being talked over."
		else:
			transmitting()

	if event.is_action_released("radioptt"):
		transmitted()

func transmitting():
	transmit = true
	if recognition:
		recognition.start()
	if DisplayServer.tts_is_speaking():
		DisplayServer.tts_pause()
	print("Transmitting")
	textbox.text = "Transmitting"
func transmitted():
	transmit = false
	if recognition:
		recognition.stop() 
	DisplayServer.tts_resume()
	print("Transmitted: ")
	

func _on_speech_result(args):
	var event = args[0]
	var results = event.results
	var transcript_output = ""
	
	# Extract the transcript from the JS results object
	for i in range(event.resultIndex, results.length):
		transcript_output += results[i][0].transcript

	speechprocessing(transcript_output)

func speechprocessing(voiced: String):
	voiced = voiced.to_lower().replace("'", "").strip_edges()
	voiced = voiced.replace("-","")
	voiced = voiced.replace("/","")
	print("RECOGNIZED: ", voiced)
	textbox.text = voiced
	# Logic for Alpha Check
	var bullseye = controller.bullseyename.to_lower()
	if ("alpha check" in voiced or "alfa check" in voiced) and bullseye in voiced:
		var del = voiced.find(bullseye) + bullseye.length()
		var said = voiced.substr(del).strip_edges()
		controller.hasalphaceheck(said)
			
	if "new picture" in voiced:
		for x in range(controller.hostile_list.size()):
			controller.hostile_list[x].groupn = ""
			controller.hostile_list[x].setname()
		pass
	
	if "commit" in voiced:
		print("RADIO: Commit confirmed.")
		controller.hascommited()
		
	if "miles" in  voiced or "mile" in  voiced:
		if controller.timelineevent == 3:
			print("RADIO: redec confirmed")
			controller.hasredec()
	if "targeted" in  voiced:
		targetseparator(voiced)
	if ("new picture" in voiced) or (("single group" in voiced) and (voiced.contains("maneuver")==false)) or ("azimuth" in voiced) or ("azmuth" in voiced) or ("range" in voiced) or ("wall" in voiced) or ("ladder" in voiced) or ("champagne" in voiced) or ("vic" in voiced) or ("box" in voiced) or  ("clean" in voiced):    #("leading edge" in voiced) or ("packages" in voiced) or
		if "new picture" in voiced:
			picturedecoder(voiced)
		#	print("They said new pic")
		if(controller.timelineevent == 2):
			
			picturedecoder(voiced)
			controller.timeline[2] = true
			controller.timelineevent = 3
		else:
			print("asdadssadsadsad")
		#picturedecoder(voiced)
		pass
		
func targetseparator(qc: String):
	if controller.timelineevent<4:
		return
	regex.compile("(?P<fltnum>one|two|three|four|1|2|3|4)\\s+targeted\\s+(?P<groupname>[\\w\\s]+?)\\s+group")
	var matches = regex.search_all(qc)
	for x in matches:
		var fltnum = x.get_string("fltnum")
		var groupname = x.get_string("groupname").strip_edges()
		print("Flight ", fltnum, " targeting: ", groupname)
		match fltnum:
			"one", "1":
				controller.qctargeting(0,groupname)
				pass
			"two", "2":
				controller.qctargeting(1,groupname)
			"three", "3":
				controller.qctargeting(2,groupname)
			"four", "4":
				controller.qctargeting(3,groupname)
	pass
func picturedecoder(picture: String):
	picture.replace("to","2")
	if"doingus spoingus" in picture: #packages
		pass
		#package stuff done later
	if"bingus bongus" in picture: #leading edge
		pass
	elif "single group" in picture:
		#if controller.timeline[2] == true:
			#var groupinfo: Array = groupdecoder(picture)
			#controller.singlegroup(groupinfo[0],groupinfo[1],groupinfo[2])
		#else:
			#print("Gave out a core didnt you?")
		var groupinfo: Array = groupdecoder(picture)
		controller.singlegroup(groupinfo[0],groupinfo[1],groupinfo[2])

	elif ("azimuth" in picture) or ("azmuth" in picture):
		regex.compile("muth\\W*(?P<azimuthwide>\\d+)")
		var azimuth = regex.search(picture)
		var dimension: int
		var group: Array
		if(azimuth):
			dimension = azimuth.get_string("azimuthwide").to_int()
		regex.compile("(?P<label>\\w+)\\s+group\\s+(?P<info>.*?)(?=\\w+\\s+group|$)")
		var twogroupsregex = regex.search_all(picture)
		for x in twogroupsregex:
			var groupn = x.get_string("label")
			var pregroupinfo = x.get_string("info")
			var groupinfo: Array =  groupdecoder(pregroupinfo)
			group.append([groupn,groupinfo])
		group.pop_front()
		if(dimension<10):
			pass
			group[1][1].pop_front()
			group[1][1].pop_front()
			#group[1].pop_front()
		controller.twogrpazimuth(group,dimension)
	elif "range" in picture:
		regex.compile("range\\W*(?P<rangedeep>\\d+)")
		var range = regex.search(picture)
		var group: Array
		regex.compile("(?P<label>\\w+)\\s+group\\s+(?P<info>.*?)(?=\\w+\\s+group|$)")
		var twogroupsregex = regex.search_all(picture)
		for x in twogroupsregex:
			var groupn = x.get_string("label")
			var pregroupinfo = x.get_string("info")
			var groupinfo: Array =  groupdecoder(pregroupinfo)
			group.append([groupn,groupinfo])
		group.pop_front()
		group[1][1].pop_front()
		group[1][1].pop_front()
		print(group)
		controller.ladder(group)
		pass
	elif "champagne" in picture:
		regex.compile("champagne\\W*(?P<chamwide>\\d+)")
		var champagne = regex.search(picture)
		var wide: int
		var deep: int
		var group: Array
		if(champagne):
			wide = champagne.get_string("chamwide").to_int()
			regex.compile("wide\\W*(?P<chamdeep>\\d+)")
			var dim = regex.search(picture)
			deep = dim.get_string("chamdeep").to_int()
		regex.compile("(?P<dalabel>(?:\\b\\w+\\b\\s+){0,1}\\b\\w+\\b)\\s+group\\s+(?P<info>.*?)(?=(?:(?:\\b\\w+\\b\\s+){1,2}group)|$)")
		var threegrpchamp = regex.search_all(picture)
		for x in threegrpchamp:
			var groupn: String = x.get_string("dalabel")
			var pregroupinfo = x.get_string("info")
			var groupinfo: Array =  groupdecoder(pregroupinfo)
			group.append([groupn,groupinfo])
		group.pop_front()
		regex.compile("^(\\w+)")
		var tempp: String = regex.search(group[0][0]).get_string()
		if((picture.contains("weighted") or picture.contains("waited")) and tempp.length()>1):
			tempp = tempp.substr(tempp.length()-1) + "lead"
			group[0][0] = tempp
			pass
			
		if(wide<10):
			group[1][1].pop_front()
			group[1][1].pop_front()
		group[2][1].pop_front() #check and debug to see how it works for if it is not less than 10
		group[2][1].pop_front()
		group[2][0] = "trail"
		print(group)
		controller.threegroupchampagne(group,wide,deep)
	elif "vic" in picture:
		regex.compile("vic\\W*(?P<vicdeep>\\d+)")
		var vic = regex.search(picture)
		var wide: int
		var deep: int
		var group: Array
		if(vic):
			deep = vic.get_string("vicdeep").to_int()
			regex.compile("deep\\W*(?P<vicwide>\\d+)")
			var dim = regex.search(picture)
			wide = dim.get_string("vicwide").to_int()
		regex.compile("(?P<dalabel>(?:\\b\\w+\\b\\s+){0,1}\\b\\w+\\b)\\s+group\\s+(?P<info>.*?)(?=(?:(?:\\b\\w+\\b\\s+){1,2}group)|$)")
		var threegrpvic = regex.search_all(picture)
		for x in threegrpvic:
			var groupn: String = x.get_string("dalabel")
			var pregroupinfo = x.get_string("info")
			var groupinfo: Array =  groupdecoder(pregroupinfo)
			group.append([groupn,groupinfo])
		group.pop_front()
		regex.compile("^(\\w+)")
		var tempp: String = regex.search(group[0][0]).get_string()
		group[0][0] = group[0][0].substr(group[0][0].length()-4)	
		group[1][1].pop_front()
		group[1][1].pop_front()
		group[2][1].pop_front() 
		group[2][1].pop_front()

		print(group)
		controller.threegrpvic(group,wide,deep)
		pass
	elif "wall" in picture:
		regex.compile("\\b(\\w+)\\s+group\\s+wall\\b")
		var howmany = regex.search(picture)
		var howmanygrps: String = howmany.get_string()
		#print(howmanygrps)
		var group: Array
		regex.compile("(?P<label>\\w+)\\s+group\\s+(?P<info>.*?)(?=\\w+\\s+group|$)")
		var wall = regex.search_all(picture)
		for x in wall:
			var groupn = x.get_string("label")
			var pregroupinfo = x.get_string("info")
			var groupinfo: Array =  groupdecoder(pregroupinfo)
			group.append([groupn,groupinfo])
		group.pop_front()
		for x in range(1,group.size()-1):
			group[x][1].pop_front()
			group[x][1].pop_front()
			pass 
		if((picture.contains("weighted") or picture.contains("waited"))):
				var temp = group[0][0]
				group[0][0] = temp.substr(temp.length() - 1)
		if howmanygrps == "4 group wall" or howmanygrps == "four group wall" or howmanygrps == "for group wall":
			print(group)
			controller.fourgrpwall(group)
		elif howmanygrps == "5" or howmanygrps == "five group wall":
			controller.fivegrpwall(group)
		else:
			#if((picture.contains("weighted") or picture.contains("waited"))):
				#var temp = group[0][0]
				#group[0][0] = temp.substr(temp.length() - 1)
			controller.threegrpwall(group)
	elif "ladder" in picture:
		regex.compile("(?P<label>\\w+)\\s+group\\s+(?P<info>.*?)(?=\\w+\\s+group|$)")
		var group: Array
		var ladder = regex.search_all(picture)
		for x in ladder:
			var groupn = x.get_string("label")
			var pregroupinfo = x.get_string("info")
			var groupinfo: Array =  groupdecoder(pregroupinfo)
			group.append([groupn,groupinfo])
		group.pop_front()
		for x in range(1,group.size()):
			group[x][1].pop_front()
			group[x][1].pop_front()
		controller.ladder(group)
	elif "clean" in picture:
		print("CLEAN PIC KNOCK IT OFF!")
		controller.knockitoff()
	elif "additional group" in picture:
		var groupinfo: Array = groupdecoder(picture)
		#controller.singlegroup(groupinfo[0],groupinfo[1],groupinfo[2]) create additional group func
		pass
	elif "pop up ground" in picture:
		var groupinfo: Array = groupdecoder(picture)
		#controller.singlegroup(groupinfo[0],groupinfo[1],groupinfo[2]) create pop up group func
		pass
	elif "threat group" in picture:
		var groupinfo: Array = groupdecoder(picture)
		#controller.singlegroup(groupinfo[0],groupinfo[1],groupinfo[2]) create threat group func
		pass
		
func groupdecoder(singlegroup:String):
	regex.compile("\\d[\\d\\s\\-a-zA-Z]*\\d")
	var sglocation: String
	var sglocationbear: int 
	var sglocationrng: int
	var location= regex.search(singlegroup)
	if location:
		sglocation = location.get_string()
		sglocation = sglocation.replace("-","")
		sglocationbear= sglocation.substr(0,3).to_int()
		sglocationrng= sglocation.substr(3,2).to_int()
	regex.compile("(?P<num>to|two|three|four|five|six|2|3|4|5|6)\\s*(?:hostile|contacts)")
	var contacts = regex.search(singlegroup)
	var sgstrength = 1
	if contacts:
		var sgcontacts = contacts.get_string("num")
		match sgcontacts:
			"to", "two", "2":
				sgstrength = 2
			"three", "3":
				sgstrength = 3
			"four", "4":
				sgstrength = 4
			"five", "5":
				sgstrength = 5
			"six", "6":
				sgstrength = 6
	#print("The group is at bullseye ",sglocationbear,"/",sglocationrng, " and the amount of contacts is ",sgstrength)
	return [sglocationbear,sglocationrng,sgstrength]
	
