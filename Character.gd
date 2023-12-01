extends CharacterBody2D


@onready var main = get_node("/root/main")
const SPEED = 300.0
@export var JUMP_VELOCITY = -400.0
@export var air_jump_modifier = 0.7
@export var air_jumps_max = 1
@onready var arrow = $RayCast2D
@onready var above_check = $AboveCheck
var arrow_damage = 1
var direction
var air_jumps_left = air_jumps_max
var can_jump = true
var is_facing_right = true
var last_frame
var run_started = false
var last_air_status
var air_status
var last_frame_progress

var is_running = false
var is_jumping = false
var is_crouching = false
var is_sliding = false
var is_shooting = false
var is_falling = false

var run_just_started = false
var jump_just_started = false
var crouch_just_started = false
var slide_just_started = false
var shoot_just_started = false

var just_stopped_animation = [ false,false,false,false,false,false,false]
var just_started_animation = [false,false,false,false,false,false,false]
var current_animation = [true,false,false,false,false,false,false]

var idling = 0
var running = 1
var jumping = 2
var crouching = 3
var sliding = 4
var shooting = 5
var falling = 6

var frame = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	position = main.get_node("Start_Point").position

func _physics_process(delta):
	
	# sound effects
	if just_started_animation[shooting] and $RayCast2D.is_colliding():
		$ShotSound.play()
		
	if just_started_animation[running]:
		main.footstep()
	
	# prevent getting stuck while sliding
	if is_falling and above_check.is_colliding():
		position.y-=20
		velocity.y=0
		crouch()
		
	#prevent infinite falling
	if is_falling and velocity.y > 1000:
		velocity.y = 0
		position.y -= 20
		
	
	# refresh jumps after landing
	if is_on_floor():
		is_jumping = false
		air_jumps_left = air_jumps_max
	
	# gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		

	# Handle Jump.
	if Input.is_action_just_pressed(&"Jump") and not above_check.is_colliding() and not is_sliding:
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			main.make_puff(&"ground_jump")
			is_jumping = true
			
		elif air_jumps_left > 0:
			velocity.y = JUMP_VELOCITY*air_jump_modifier
			main.make_puff(&"air_jump")
			is_jumping = true
			air_jumps_left -= 1
		
	# monitoring for checks on landing
	air_status = is_on_floor()
		
		
	# attack logic
	if Input.is_action_just_pressed(&"Attack"):
		if is_on_floor():
			is_shooting = true
			$Sprite.set_animation(&"shoot")
			if arrow.is_colliding():
				var enemy = arrow.get_collider()
				if enemy.has_method("hit"):
					enemy.hit(arrow_damage)
	
			
			
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
		
		
	
	if Input.is_action_pressed(&"Crouch") and is_on_floor():
		crouch()
		
		
	if Input.is_action_just_released(&"Crouch"):
		is_crouching = false
	
	if Input.is_action_just_pressed(&"misc"):
		main.camera_change()
	
	
	if is_jumping:
		if velocity.y < 0:
			$Sprite.set_animation(&"jumping")
	if velocity.y > 0+300:
		$Sprite.set_animation(&"falling")
		is_falling = true
	else:
		is_falling = false
		
	if not $Sprite.is_playing():
		$Sprite.play()
		
	if just_landed():
		main.make_puff(&"land")
	
	#Make a footstep sound on the frames where the foot hits the ground
	if $Sprite.animation == &"run":
		if ($Sprite.frame == 2 and $Sprite.frame_progress<last_frame_progress) or ($Sprite.frame == 5 and $Sprite.frame_progress < last_frame_progress):
			main.footstep()
		last_frame_progress = $Sprite.frame_progress
	
	if last_frame == $Sprite.animation:
		just_stopped_animation.fill(false)
		just_started_animation.fill(false)
	
	#Checks for transition logic
	last_frame = $Sprite.animation
	last_air_status = is_on_floor()
	
	#Movement type
	move_and_slide()


func _on_sprite_animation_finished():
	if $Sprite.animation == &"shoot":
		is_shooting = false
		



func _on_sprite_animation_changed():
	if last_frame == &"shoot":
		is_shooting = false
	if last_frame == &"run":
		run_started = false
	
	#Current code for animation switch data gathering
	#There is a bug that causes multiple values to be true at once in just_stopped at the beginning of the game.
	if last_frame:
		var last_action = get_change_index(last_frame)
		var curr_action = get_change_index($Sprite.animation)
		
		just_stopped_animation[last_action] = true
		just_started_animation[curr_action] = true
		

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
	
	
func crouch():
	is_crouching = true
	if velocity.x > 0:
		velocity.x += SPEED/3
	elif velocity.x < 0:
		velocity.x -= SPEED/3
	velocity.x = move_toward(velocity.x,0,SPEED/4)
	if velocity.x != 0:
		slide()
		is_crouching = false
	else:
		is_sliding = false
		$Sprite.set_animation(&"crouch")
		set_hitbox($CrouchingHitbox)
	

func move(run_direction, go):
	direction_check(run_direction)
	if go:
		velocity.x = run_direction*SPEED
	if go and is_on_floor():
		$Sprite.set_animation(&"run")
		set_hitbox($StandingHitbox)
		if check_start_of() and not just_landed():
			main.make_puff(&"run")
		is_running = true
		
		
		
	if not go:
		is_running = false
		
		velocity.x = move_toward(velocity.x, 0, SPEED/7)
		if is_on_floor() and velocity.x == 0:
			is_sliding = false
		if is_on_floor() and not is_crouching and not is_shooting and not is_sliding and not above_check.is_colliding():
			$Sprite.set_animation(&"idle")
			set_hitbox($StandingHitbox)
		elif is_on_floor() and above_check.is_colliding():
			crouch()

func get_change_index(animation):
	if animation == &"idle":
		return idling
	if animation == &"run":
		return running
	if animation == &"jumping":
		return jumping
	if animation == &"crouch":
		return crouching
	if animation == &"slide":
		return sliding
	if animation == &"shoot":
		return shooting
	if animation == &"falling":
		return falling


func slide():
	is_sliding = true
	$Sprite.set_animation(&"slide")
	set_hitbox($SlidingHitbox)
	if check_start_of():
		main.make_puff(&"slide")

func _on_sprite_frame_changed():
	pass
