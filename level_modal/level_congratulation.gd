extends CanvasLayer

signal menu_requested

@onready var return_button: TextureButton = $TextureRect/volver_menu

func _ready() -> void:

	process_mode = PROCESS_MODE_WHEN_PAUSED
	return_button.pressed.connect(_on_return_button_pressed)
	

func _on_return_button_pressed() -> void:
	get_tree().paused = false	
	menu_requested.emit()
	queue_free()
