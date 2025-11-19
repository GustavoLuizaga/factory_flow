extends Control

#Boton sandwich
@onready var user_menu: MenuButton = $"UserMenu"
# Panel de perfil
var profile_panel_scene : PackedScene = preload("res://Menu/profile_panel.tscn")
# SOLO declaramos el tipo, sin asignar null
var profile_panel: Control

func _ready() -> void:
	_setup_user_menu()
	user_menu.text = "☰"
	user_menu.add_theme_font_size_override("font_size", 35)

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
