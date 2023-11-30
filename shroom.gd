extends CharacterBody2D


const SPEED = 75
const JUMP_VELOCITY = -400.0
var jump = 0
var starting_health = 10
var health = starting_health
var alive = true
var last_frame
var direction = 1
@onready var check_ground = $RayCheckGround
@onready var check_obstacle = $ShapeCheckObstacle

var is_facing_right = true
var dying = false
var being_hit = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	# Add the gravity.
	if alive:
		if not $Sprite.is_playing():
			$Sprite.play()
			
		
		if not is_on_floor():
			velocity.y += gravity * delta
			

		# Handle Jump.
		if jump:
			velocity.y = JUMP_VELOCITY
			
		#Automated Locomotion
			
			

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		
		if check_obstacle.is_colliding():
			turn_around()
		
		if is_on_floor() and not check_ground.is_colliding():
			turn_around()
		
		if direction and not being_hit:
			if not dying and not being_hit:
				$Sprite.set_animation(&"walk")
				velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			if not dying and not being_hit:
				$Sprite.set_animation(&"idle")
		
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()

	last_frame = $Sprite.frame

func die():
	dying = true
	being_hit = false
	$Sprite.set_animation(&"die")
	$Sprite.play()
	set_collision_mask_value(1,false)
	set_collision_layer_value(3,false)
	alive = false

func hit(damage):
	being_hit = true
	$Sprite.set_animation(&"hit")
	$Sprite.set_frame(0)
	health -= damage


	
	


func _on_sprite_animation_finished():
	if $Sprite.animation == &"hit":
		being_hit = false
		if health <= 0:
			die()
		else:
			$Sprite.set_animation(&"idle")
			
func revive():
	print("alive")
	dying = false
	health = starting_health
	alive = true
	$Sprite.set_animation(&"idle")
	set_collision_mask_value(1,true)
	set_collision_layer_value(3,true)
	
func turn_around():
	direction *= -1
	if direction > 0:
		is_facing_right = true
		$Sprite.set_flip_h(false)
		check_obstacle.target_position.x = 20
		check_ground.target_position.x = 27
	elif direction < 0:
		is_facing_right = false
		$Sprite.set_flip_h(true)
		check_obstacle.target_position.x = -20
		check_ground.target_position.x = -27
