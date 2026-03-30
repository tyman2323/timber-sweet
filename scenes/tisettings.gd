extends Control


@onready var bullname: TextEdit = $bename
@onready var controllercs: TextEdit = $contcs
@onready var fightercs: TextEdit = $ftrcs
@onready var totalhostiles: TextEdit = $tot
@onready var orientation: CheckBox = $ns
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	var ns:bool
	var totalh = totalhostiles.text
	totalh = totalh.replace(" ","")
	totalh = totalh.to_int()
	var bn = bullname.text
	bn = bn.replace(" ","")
	var ccs = controllercs.text
	ccs = ccs.replace(" ","")
	var fcs = fightercs.text
	fcs = fcs.replace(" ","")
	if(orientation.button_pressed):
		ns = true
	var main = load("res://scenes/game.tscn").instantiate()
	main.bullseyename = bn
	main.controllercs = ccs
	main.ftrcs = fcs
	main.northsouth = ns
	main.hostiletot = randi_range(1,totalh)
	get_tree().root.add_child(main)
	get_tree().current_scene.queue_free()



func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/titlescreen.tscn")
