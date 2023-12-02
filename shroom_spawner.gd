extends Marker2D

var shroom = preload("res://shroom.tscn")
@onready var main = get_node("/root/main")
@export var spawn_cap = 2
var can_spawn = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if get_tree().get_nodes_in_group(str(self.name)).size() < spawn_cap and can_spawn:
		var new_shroom = shroom.instantiate()
		new_shroom.add_to_group(str(self.name))
		new_shroom.position = position
		main.add_child(new_shroom)
		can_spawn = false
		$SpawnTimer.start()

func _on_spawn_timer_timeout():
	can_spawn = true
