extends WaveFunction2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_init()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	process_control()
