# res://Scripts/login_screen.gd
extends Control

# Referencias a campos de texto y etiqueta de error
@onready var username_edit: LineEdit = $ColorRect/Panel/VBoxContainer/UsernameEdit
@onready var password_edit: LineEdit = $ColorRect/Panel/VBoxContainer/PasswordEdit
@onready var error_label:  Label    = $ColorRect/Panel/VBoxContainer/ErrorLabel

func _ready() -> void:
	# Asegurar que no haya texto viejo
	username_edit.text = ""
	password_edit.text = ""
	error_label.text   = ""
	get_tree().paused  = false   # por si vienes de un nivel

# Botón "Entrar"
func _on_BtnLogin_pressed() -> void:
	var username: String = username_edit.text
	var password: String = password_edit.text
	# Pedimos al backend que valide
	var ok: bool = ProgressManager.login(username, password)
	if not ok:
		error_label.text = "Usuario o contraseña incorrectos."
		return

	# Si todo bien, vamos a selección de nivel o donde tú decidas
	get_tree().change_scene_to_file("res://Menu/level_select.tscn")

# Botón "Registrarse"
func _on_BtnGoRegister_pressed() -> void:
	get_tree().change_scene_to_file("res://Menu/register_screen.tscn")

# Botón "Volver al menú"
func _on_BtnBack_pressed() -> void:
	get_tree().change_scene_to_file("res://Menu/menu.tscn")
