extends Control

#@onready var username_modal: UsernameModal = $UsernameModal   # NUEVO
# NUEVO: escena del modal y variable para la instancia
var UsernameModalScene := preload("res://Menu/username_modal.tscn")
var username_modal: UsernameModal = null
# Panel de perfil
#var profile_panel_scene : PackedScene = preload("res://Menu/profile_panel.tscn")
# SOLO declaramos el tipo, sin asignar null
var profile_panel: Control

func _ready() -> void:
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
	#pass # Replace with function body.
	# Abrir pantalla de perfil/opciones
	get_tree().change_scene_to_file("res://Menu/profile_screen.tscn")


func _on_button_3_pressed() -> void:
	get_tree().quit()
