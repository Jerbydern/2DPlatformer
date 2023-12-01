extends Node2D

@export var puff: PackedScene

var curr_footstep = 0
var can_footstep = true
var footstep_sounds
var camera = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	$Player.get_node("Sprite").play(&"idle")
	$Shroom.get_node("Sprite").play(&"idle")
	footstep_sounds = get_node("./Player/footsteps").get_children()
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Global.debug:
		
		if Input.is_action_just_pressed(&"debug1") and not Input.is_action_pressed(&"debug2"):
			camera_change()
		
		if Input.is_action_just_pressed(&"debug2"):
			print("reviving")
			var enemies = get_tree().get_nodes_in_group("enemies")
			for enemy in enemies:
				enemy.revive()
		
		if Input.is_action_pressed(&"debug1") and Input.is_action_pressed(&"debug2"):
			position = get_node("Start_Point").position
	
func delete_puff():
	var puffs = get_tree().get_nodes_in_group("puffs")
	for this_puff in puffs:
		if this_puff.done:
			this_puff.queue_free()
			

		
func make_puff(puff_type):
	var this_puff = puff.instantiate()
	this_puff.position = $Player.position
	if $Player.is_facing_right:
			this_puff.set_flip_h(true)
	this_puff.connect("animation_finished", delete_puff)
	this_puff.set_animation(puff_type)
	if puff_type == &"ground_jump":
		
		this_puff.scale *= 0.5
		this_puff.position.y += 6
	elif puff_type == &"slide":
		this_puff.position.y += 15
	elif puff_type == &"run":
		this_puff.position.y += 5
	elif puff_type == &"land":
		this_puff.position.y += 16
		this_puff.scale *= 0.4
	add_child(this_puff)
	this_puff.play()


func _on_footstep_timer_timeout():
	can_footstep = true
	
func footstep():

		footstep_sounds[curr_footstep].play(0)
		if curr_footstep < footstep_sounds.size() -1:
			curr_footstep += 1
		else:
			curr_footstep = 0
	


func camera_change():
	var playercam = get_node("Player/PlayerCamera")
	var shroomcam = get_node("Shroom9/ShroomCamera")
	if playercam.enabled:
		playercam.set_enabled(false)
		shroomcam.set_enabled(true)
	elif shroomcam.enabled:
		playercam.set_enabled(true)
		shroomcam.set_enabled(false)
			
		
