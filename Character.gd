extends CharacterBody2D


@onready var main = get_node("/root/main")
@onready var SPEED = 200
@export var JUMP_VELOCITY = -400.0
@export var air_jump_modifier = 0.7
@export var air_jumps_max = 1
@onready var arrow = $RayCast2D
@onready var above_check_ray = $AboveCheck
@onready var above_check
@export var arrow_damage = 1
@export var arrow_knockback = 100
@export var health = 3
var direction
var air_jumps_left = air_jumps_max
var is_facing_right = true
var last_frame
var run_started = false
var last_air_status
var air_status
var last_frame_progress
var can_shoot=true
var invulnerable = false

var run_just_started = false
var jump_just_started = false
var crouch_just_started = false
var slide_just_started = false
var shoot_just_started = false

var just_stopped_animation = [false,false,false,false,false,false,false,false,false,false,false, false]
var just_started_animation = [false,false,false,false,false,false,false,false,false,false,false, false]
var current_animation = [false,false,false,false,false,false,false,false,false,false,false,false]

var idling = 0
var running = 1
var jumping = 2
var crouching = 3
var sliding = 4
var shooting = 5
var falling = 6
var air_shooting = 7
var crouch_walking = 8
var jump_starting = 9
var jump_earlying = 10
var hitting = 11

var frame = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	position = main.get_node("Start_Point").position

func _physics_process(delta):
	#print($Sprite.animation)
	
	
	#assignments
	above_check = above_check_ray.is_colliding()
	
	# sound effects
	if (just_started_animation[shooting] or just_started_animation[air_shooting]) and arrow.is_colliding():
		$ShotSound.play()
	elif (just_started_animation[shooting] or just_started_animation[air_shooting]):
		$ShotMissed.play()
		
	if just_started_animation[running]:
		main.footstep()
	
	# prevent getting stuck while sliding
	if current_animation[falling] and above_check:
		position.y-=20
		velocity.y=0
		crouch()
	
	
	# prevent getting stuck in slide
	if current_animation[sliding] and velocity.x == 0 and not above_check and not Input.is_action_pressed(&"Crouch"):
		idle()
	

	#prevent infinite falling
	if current_animation[falling] and velocity.y > 1000:
		velocity.y = 0
		position.y -= 20
		
	if current_animation[idling] and not is_on_floor():
		$Sprite.set_animation(&"jumping")
	
	if current_animation[jumping] and above_check and is_on_floor():
		crouch()
	
	# refresh jumps after landing
	if is_on_floor():
		air_jumps_left = air_jumps_max
	
	# gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		

	# Handle Jump.
	if Input.is_action_just_pressed(&"Jump") and not above_check and not current_animation[sliding]:
		
		if is_on_floor():
			jump_start()
			"""
			velocity.y = JUMP_VELOCITY
			main.make_puff(&"ground_jump")
			"""
		if air_jumps_left > 0 and not is_on_floor():
			air_jump()
		
	# monitoring for checks on landing
	air_status = is_on_floor()
		
		
	# shooting logic
	if Input.is_action_just_pressed(&"Attack") and can_shoot and not current_animation[crouching]:
		if is_on_floor():
			$Sprite.set_animation(&"shoot")
			can_shoot = false
			if arrow.is_colliding():
				var enemy = arrow.get_collider()
				if enemy.has_method("hit"):
					enemy.hit(arrow_damage,arrow_knockback,is_facing_right)
		else:
			$Sprite.set_animation(&"air_shoot")
			if arrow.is_colliding():
				var enemy = arrow.get_collider()
				if enemy.has_method("hit"):
					enemy.hit(arrow_damage, arrow_knockback/1.5, is_facing_right)
			
			
	# Get the input direction and handle the movement/deceleration.
	direction = Input.get_axis(&"Left", &"Right") * 2
	if direction >1:
		direction = 1
	elif direction <-1:
		direction = -1
	if direction and not current_animation[sliding] and not current_animation[shooting] and not current_animation[jump_starting] and not current_animation[jump_earlying]:
		move(direction,true)
			
	else:
		move(direction, false)
		
		
	
	if Input.is_action_just_pressed(&"Crouch") and is_on_floor() and not above_check:
		down()
		
	if current_animation[sliding] and velocity.x == 0:
		if Input.is_action_pressed(&"Crouch") or above_check:
			crouch()
		else:
			idle()
			
	if Input.is_action_pressed(&"Crouch") and not current_animation[sliding] and is_on_floor():
		crouch()
		
	if current_animation[crouch_walking] and not direction:
		crouch()
		
	if current_animation[crouching] and not above_check and not Input.is_action_pressed(&"Crouch"):
		idle()
		
	if current_animation[crouch_walking] and not above_check and not Input.is_action_pressed(&"Crouch"):
		idle()
	
	#if Input.is_action_just_released(&"Crouch") and not above_check:
		#idle()
	
	if Input.is_action_just_pressed(&"misc"):
		main.camera_change()
	
	
	if current_animation[jumping]:
		if velocity.y < 0 and not current_animation[air_shooting] and not is_on_floor():
			$Sprite.set_animation(&"jumping")
	if velocity.y > 0+300 and not current_animation[air_shooting]:
		$Sprite.set_animation(&"falling")
		
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
		idle()
	if $Sprite.animation == &"air_shoot":
		idle()
	if $Sprite.animation == &"jump_start":
		jump_early()
	if $Sprite.animation == &"jump_early":
		$Sprite.set_animation(&"jumping")
	if $Sprite.animation == &"hit":
		invulnerable = false
		$Sprite.set_animation(&"idle")



func _on_sprite_animation_changed():
	if last_frame == &"run":
		run_started = false
	
	#Current code for animation switch data gathering
	#There is a bug that causes multiple values to be true at once in just_stopped at the beginning of the game.
	if last_frame:
		var last_action = get_change_index(last_frame)
		var curr_action = get_change_index($Sprite.animation)
		current_animation.fill(false)
		current_animation[curr_action] = true
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
	

func move(run_direction, go):
	direction_check(run_direction)
	if go and not current_animation[crouch_walking] and not current_animation[crouching]:
		velocity.x = run_direction*SPEED
	elif go and (current_animation[crouch_walking] or current_animation[crouching]):
		velocity.x = run_direction*SPEED/3
		$Sprite.set_animation(&"crouch_walk")
	if go and is_on_floor() and not above_check and not current_animation[crouch_walking] and not current_animation[crouching] and not current_animation[jump_earlying] and not just_started_animation[jumping]:
		$Sprite.set_animation(&"run")
		set_hitbox($StandingHitbox)
		if check_start_of() and not just_landed():
			main.make_puff(&"run")
		
		
		
	if not go:
		velocity.x = move_toward(velocity.x, 0, SPEED/7)
		if is_on_floor() and not current_animation[crouching] and not current_animation[shooting] and not current_animation[sliding] and not current_animation[jump_starting] and not current_animation[jump_earlying] and not current_animation[hitting] and not above_check:
			idle()
		elif is_on_floor() and above_check and not current_animation[sliding]:
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
	if animation == &"air_shoot":
		return air_shooting
	if animation == &"crouch_walk":
		return crouch_walking
	if animation == &"jump_start":
		return jump_starting
	if animation == &"jump_early":
		return jump_earlying
	if animation == &"hit":
		return hitting


func slide():
	$Sprite.set_animation(&"slide")
	set_hitbox($SlidingHitbox)
	if check_start_of():
		main.make_puff(&"slide")
	velocity.x += direction * SPEED

func _on_sprite_frame_changed():
	pass
	
func idle():
	$Sprite.set_animation(&"idle")
	set_hitbox($StandingHitbox)
	can_shoot = true
	invulnerable = false

func down():
	if direction:
		slide()
	else:
		crouch()

func crouch():
	set_hitbox($CrouchingHitbox)
	if direction:
		$Sprite.set_animation(&"crouch_walk")
	else:
		$Sprite.set_animation(&"crouch")
	
func jump_start():
	$Sprite.set_animation(&"jump_start")
	set_hitbox($CrouchingHitbox)
	
func jump_early():
	# as in the early part of the jump
	$Sprite.set_animation(&"jump_early")
	if Input.is_action_pressed(&"Jump"):
		velocity.y = JUMP_VELOCITY
	else:
		velocity.y = JUMP_VELOCITY/1.3
		
func air_jump():
	velocity.y = JUMP_VELOCITY*air_jump_modifier
	$Sprite.set_animation(&"jumping")
	main.make_puff(&"air_jump")
	air_jumps_left -= 1

func hit(damage,knockback,coming_from_right):
	print("triggered")
	if not invulnerable:
		$Sprite.set_animation(&"hit")
		$Sprite.set_frame(0)
		if coming_from_right:
			velocity += Vector2(knockback,-knockback/3)
		else:
			velocity += Vector2(-knockback,-knockback/3)
		health -= damage
		invulnerable = true
