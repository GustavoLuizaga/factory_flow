extends CanvasLayer

## El modal "anuncia" (emite) que un botón fue presionado.
## No sabe qué nivel sigue, solo avisa. ¡Esto lo hace reutilizable!
signal menu_requested
signal next_level_requested

# Referencias a nuestros botones invisibles
@onready var menu_button: TextureButton = $TextureRect/MenuButton
@onready var next_level_button: TextureButton = $TextureRect/NextLevelButton


func _ready() -> void:
	# Conectar la señal "pressed" (cuando se hace clic) de cada botón
	# a una función en este mismo script.
	process_mode = PROCESS_MODE_WHEN_PAUSED
	menu_button.pressed.connect(_on_menu_button_pressed)
	next_level_button.pressed.connect(_on_next_level_button_pressed)
	
	# El modal debe empezar oculto. Lo mostraremos cuando el jugador gane.
	hide()


# Esta es la función que tu Nivel (Level01.gd) llamará
func show_modal(show_next_level_btn: bool = true) -> void:
	# Mostrar el modal
	show()
	
	# Ocultar el botón "Siguiente Nivel" si es el último nivel
	next_level_button.visible = show_next_level_btn
	
	# Pausar el juego que está detrás
	get_tree().paused = true


# Se llama cuando se presiona el botón "Volver al Menú"
func _on_menu_button_pressed() -> void:
	# Quitar la pausa antes de cambiar de escena
	get_tree().paused = false
	
	# "Anunciar" que el jugador quiere ir al menú
	menu_requested.emit()
	
	# Destruir el modal para limpiar la memoria
	queue_free()


# Se llama cuando se presiona el botón "Siguiente Nivel"
func _on_next_level_button_pressed() -> void:
	get_tree().paused = false
	
	# "Anunciar" que el jugador quiere ir al siguiente nivel
	next_level_requested.emit()
	
	queue_free()
