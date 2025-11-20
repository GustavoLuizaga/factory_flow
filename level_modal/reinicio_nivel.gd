extends Control

# 1. Definir las señales que EconomyManager está esperando
signal retry_level
signal return_to_menu

# --- ¡AQUÍ ESTÁ EL ARREGLO! ---
# Tus nodos son "TextureButton", no "Button".
# Cambiamos el TIPO de la variable de ": Button" a ": TextureButton".
@onready var menu_button: TextureButton = $ColorRect/TextureRect/MenuButton
@onready var retry_button: TextureButton = $ColorRect/TextureRect/Reintentar


# 2. Conectar los botones a las funciones automáticamente
func _ready() -> void:
	# Conectar la señal "pressed" de cada botón a su función
	if menu_button:
		menu_button.pressed.connect(_on_menu_button_pressed)
	else:
		print("ERROR: No se encontró 'MenuButton' en la ruta $ColorRect/TextureRect/MenuButton")

	if retry_button:
		# Conectamos el botón de reintentar a la función de reintentar
		retry_button.pressed.connect(_on_reintentar_pressed)
	else:
		print("ERROR: No se encontró 'NextLevelButton' en la ruta $ColorRect/TextureRect/Reintentar")


# 3. Esta es la función que EconomyManager llama para mostrar la ventana
func show_popup() -> void:
	show()
	get_tree().paused = true


# 4. Funciones que se ejecutan al presionar los botones
func _on_menu_button_pressed() -> void:
	hide() # Ocultar la ventana
	get_tree().paused = false # ¡Muy importante despausar el juego!
	get_tree().change_scene_to_file("res://Menu/level_select.tscn")     # Emitir la señal


# Esta es la función para REINTENTAR
func _on_reintentar_pressed() -> void:
	hide() # Ocultar la ventana
	get_tree().paused = false # ¡Muy importante despausar el juego!
	get_tree().change_scene_to_file("res://level2/level_02.tscn")       # Emitir la señal
