extends CharacterBody2D

signal jumppuff
signal air_jumppuff
signal slidepuff
signal landpuff
signal camera_change


@onready var main = get_node("/root/main")
const SPEED = 300.0
@export var JUMP_VELOCITY = -400.0
@export var air_jump_modifier = 0.7
@export var air_jumps_max = 1
@onready var arrow = $RayCast2D
var arrow_damage = 1
var direction
var air_jumps_left = air_jumps_max
var jumping = false
var can_jump = true
var is_crouching = false
var is_shooting = false
var is_facing_right = true
var is_sliding = false
var last_frame
var slide_started = false
var run_started = false
var is_running = false
var last_air_status
var air_status

#var is_running
var is_jumping
#var is_crouching
#var is_sliding
#var is_shooting

var run_just_started = false
var jump_just_started = false
var crouch_just_started = false
var slide_just_started = false
var shoot_just_started = false


var run_stopped
var jump_stopped
var crouch_stopped
var slide_stopped
var shoot_stopped

var frame = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	position = main.get_node("Start_Point").position

func _physics_process(delta):
	# Add the gravity.
	if is_on_floor():
		jumping = false
		air_jumps_left = air_jumps_max
	
	
	if not is_on_floor():
		velocity.y += gravity * delta
		
	if air_jumps_left <= 0:
		can_jump = false
	else:
		can_jump = true

	# Handle Jump.
	if Input.is_action_just_pressed(&"Jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			
		elif can_jump:
			velocity.y = JUMP_VELOCITY*air_jump_modifier
			air_jumps_left -= 1
		jumping = true
		jumppuff.emit()
	
	air_status = is_on_floor()
		
	if Input.is_action_just_pressed(&"Attack"):
		if is_on_floor():
			is_shooting = true
			$Sprite.set_animation(&"shoot")
			if arrow.is_colliding():
				var enemy = arrow.get_collider()
				if enemy.has_method("hit"):
					enemy.hit(arrow_damage)
	
	if Global.debug:
		
		if Input.is_action_just_pressed(&"debug2"):
			print("reviving")
			var enemies = get_tree().get_nodes_in_group("enemies")
			for enemy in enemies:
				enemy.revive()
		
		if Input.is_action_pressed(&"debug1") and Input.is_action_pressed(&"debug2"):
			position = Vector2(200,200)
			
			
	# Get the input direction and handle the movement/deceleration.
	direction = Input.get_axis(&"Left", &"Right")
	direction *= 2
	if direction >1:
		direction = 1
	elif direction <-1:
		direction = -1
	if direction and not is_crouching and not is_sliding:
		move(direction,true)
			
	else:
		move(direction, false)
		velocity.x = move_toward(velocity.x, 0, SPEED/7)
		if is_on_floor() and velocity.x == 0:
			is_sliding = false
		if is_on_floor() and not is_crouching and not is_shooting and not is_sliding:
			$Sprite.set_animation(&"idle")
		
	
	if Input.is_action_pressed(&"Crouch") and is_on_floor():
		is_crouching = true
		if velocity.x > 0:
			velocity.x += SPEED/3
		elif velocity.x < 0:
			velocity.x -= SPEED/3
		velocity.x = move_toward(velocity.x,0,SPEED/4)
		if velocity.x != 0:
			$Sprite.set_animation(&"slide")
			if not slide_started:
				slidepuff.emit()
			slide_started = true
		else:
			is_sliding = false
			$Sprite.set_animation(&"crouch")
	else:
		set_hitbox($StandingHitbox)
		
		
	if Input.is_action_just_released(&"Crouch"):
		is_crouching = false
	
	if Input.is_action_just_pressed(&"misc"):
		camera_change.emit()
	
	
	if jumping:
		if velocity.y < 0:
			$Sprite.set_animation(&"jumping")
	if velocity.y > 0+300:
		$Sprite.set_animation(&"falling")
		
	if not $Sprite.is_playing():
		$Sprite.play()
		
	if just_landed():
		landpuff.emit()
	
	last_frame = $Sprite.animation
	last_air_status = is_on_floor()
	move_and_slide()


func _on_sprite_animation_finished():
	if $Sprite.animation == &"shoot":
		is_shooting = false
		



func _on_sprite_animation_changed():
	if last_frame == &"shoot":
		is_shooting = false
	if last_frame == &"slide":
		slide_started = false
	if last_frame == &"walk":
		run_started = false
	if $Sprite.animation == &"crouch":
		is_crouching = true
		is_sliding = false
		is_running = false
		is_jumping = false
		is_shooting = false
	if $Sprite.animation == &"slide":
		set_hitbox($SlidingHitbox)
		is_sliding = true
		is_running = false
		is_jumping = false
		is_shooting = false
		is_crouching = false
	if $Sprite.animation == &"walk":
		is_running = true
		is_jumping = false
		is_sliding = false
		is_shooting = false
		is_crouching = false
	if $Sprite.animation == &"shoot":
		is_shooting = true
		is_jumping = false
		is_running = false
		is_sliding = false
		is_crouching = false
	if $Sprite.animation == &"jumping":
		is_jumping = true
		is_shooting = false
		is_running = false
		is_sliding = false
		is_crouching = false
	
	if last_frame == &"crouch":
		crouch_stopped = true
	if last_frame == &"slide":
		slide_stopped = true
	if last_frame == &"walk":
		run_stopped = true

func just_landed():
	if last_air_status != air_status:
		if is_on_floor():
			return true
	return false
	
func direction_check(direction):
	if direction > 0:
		$Sprite.set_flip_h(false)
		is_facing_right = true
		arrow.set_target_position(Vector2(150,0))
	if direction < 0:
		$Sprite.set_flip_h(true)
		is_facing_right = false
		arrow.set_target_position(Vector2(-150,0))

func set_hitbox(hitbox):
	var hitboxes = get_tree().get_nodes_in_group("hitboxes")
	for iteration in hitboxes:
		iteration.set_disabled(true)
	hitbox.set_disabled(false)

func check_start_of():
	if last_frame != $Sprite.animation:
		return true
	

func move(run_direction, go):
	direction_check(run_direction)
	if go:
		velocity.x = run_direction*SPEED
	if go and is_on_floor():
		$Sprite.set_animation(&"walk")
		if check_start_of() and not just_landed():
			main.make_puff(&"run")
		is_running = true
		
		
		
	if not go:
		is_running = false
		velocity.x = move_toward(velocity.x, 0, SPEED/7)
