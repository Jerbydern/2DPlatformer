extends CharacterBody2D


const SPEED = 75
const JUMP_VELOCITY = -400.0
var jump = 0
var starting_health = 10
@export var punch_damage = 1
@export var punch_knockback = 300

var health = starting_health
var invulnerable = false
var alive = true
var last_frame
var can_attack = true
var direction = 1

@onready var cooldown = $TimerAttackCooldown
@onready var check_ground = $RayCheckGround
@onready var check_obstacle = $RayCheckObstacle
@onready var check_attack = $RayCheckAttack
@onready var punchbox = $RayCheckPunch

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
			
		
			
		if check_attack.is_colliding():
			var player = check_attack.get_collider()
			if can_attack and not player.get_node("Sprite").animation == &"hit":
				$Sprite.set_animation(&"attack")
				can_attack = false
				cooldown.start()
				
		if $Sprite.animation == &"attack" and ($Sprite.frame == 6 or $Sprite.frame == 7):
			if punchbox.is_colliding():
				print("true")
				var player = punchbox.get_collider()
				print(player)
				if player.has_method("hit"):
					player.hit(punch_damage,punch_knockback,is_facing_right)
				
		
		if check_obstacle.is_colliding():
			turn_around()
		
		if is_on_floor() and not check_ground.is_colliding():
			turn_around()
		
		#Automated Locomotion
		if direction and not $Sprite.animation == &"hit" and not $Sprite.animation == &"attack":
			if not dying and not $Sprite.animation == &"hit" and not $Sprite.animation == &"attack":
				$Sprite.set_animation(&"walk")
				velocity.x = direction * SPEED
		elif not $Sprite.animation == &"hit" and not $Sprite.animation == &"attack":
			velocity.x = move_toward(velocity.x, 0, SPEED)
			if not dying:
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

func hit(damage,knockback,coming_from_right):
	if not invulnerable:
		being_hit = true
		$Sprite.set_animation(&"hit")
		$Sprite.set_frame(0)
		if coming_from_right:
			velocity += Vector2(knockback,-knockback/3)
		else:
			velocity += Vector2(-knockback,-knockback/3)
		health -= damage
		invulnerable = true


	
	


func _on_sprite_animation_finished():
	if $Sprite.animation == &"hit":
		invulnerable = false
		being_hit = false
		if health <= 0:
			die()
		else:
			$Sprite.set_animation(&"idle")
	if $Sprite.animation == &"attack":
		$Sprite.set_animation(&"idle")
			
func revive():
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
		check_attack.target_position.x = 27
		punchbox.target_position.x = 23
	elif direction < 0:
		is_facing_right = false
		$Sprite.set_flip_h(true)
		check_obstacle.target_position.x = -20
		check_ground.target_position.x = -27
		check_attack.target_position.x = -27
		punchbox.target_position.x = -23
		



func _on_timer_attack_cooldown_timeout():
	can_attack = true
