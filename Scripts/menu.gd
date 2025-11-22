extends Control

#Boton sandwich
@onready var user_menu: MenuButton = $"UserMenu"
#@onready var username_modal: UsernameModal = $UsernameModal   # NUEVO
# NUEVO: escena del modal y variable para la instancia
var UsernameModalScene := preload("res://Menu/username_modal.tscn")
var username_modal: UsernameModal = null
# Panel de perfil
var profile_panel_scene : PackedScene = preload("res://Menu/profile_panel.tscn")
# SOLO declaramos el tipo, sin asignar null
var profile_panel: Control

func _ready() -> void:
	_setup_user_menu()
	user_menu.text = "☰"
	user_menu.add_theme_font_size_override("font_size", 55)
	# COLORES DEL TEXTO
	user_menu.add_theme_color_override("font_color", Color.BLACK)                 # normal
	user_menu.add_theme_color_override("font_hover_color", Color(0.1, 0.1, 0.1)) # cuando pasas el mouse
	user_menu.add_theme_color_override("font_pressed_color", Color(0.2, 0.2, 0.2))
	user_menu.add_theme_color_override("font_focus_color", Color(0, 0, 0))

	# CONTORNO PARA HACERLO MÁS LLAMATIVO
	user_menu.add_theme_constant_override("outline_size", 2)
	user_menu.add_theme_color_override("font_outline_color", Color(1, 1, 1))  # borde blanco
	
	_ensure_username()
	
# Garantiza que haya un usuario al entrar al menú
func _ensure_username() -> void:
	# Si ya hay usuario actual, no mostramos modal
	if ProgressManager.has_current_user():
		var profile := ProgressManager.get_current_profile()
		print("Jugador actual:", profile.get("username", ""))
		return

	# Si NO hay usuario, instanciamos el modal
	username_modal = UsernameModalScene.instantiate()
	# Añadirlo como hijo del menú
	add_child(username_modal)
	# Hacer que ocupe toda la pantalla
	username_modal.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Conectar la señal (solo una vez)
	if not username_modal.username_confirmed.is_connected(_on_username_confirmed):
		username_modal.username_confirmed.connect(_on_username_confirmed)

	# Abrir el modal
	username_modal.open()


func _on_username_confirmed(username: String) -> void:
	print("Perfil listo, jugador:", username)
	# Aquí, si quieres, actualiza un Label con el nombre

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Menu/level_select.tscn")


func _on_button_2_pressed() -> void:
	pass # Replace with function body.


func _on_button_3_pressed() -> void:
	get_tree().quit()

##NUEVO: menú desplegable del botón sandwich
# Configura las opciones del menú desplegable
func _setup_user_menu() -> void:
	var pm : PopupMenu= user_menu.get_popup()
	pm.clear()
	pm.add_item("Iniciar sesión", 1)
	pm.add_item("Registrarse", 2)
	if not pm.id_pressed.is_connected(_on_user_menu_id_pressed):
		pm.id_pressed.connect(_on_user_menu_id_pressed)

# Cuando el jugador elige una opción del sandwich
func _on_user_menu_id_pressed(id: int) -> void:
	match id:
		1: get_tree().change_scene_to_file("res://Menu/login_screen.tscn")
		2:get_tree().change_scene_to_file("res://Menu/register_screen.tscn")
