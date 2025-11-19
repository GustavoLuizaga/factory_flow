# res://Scripts/register_screen.gd
extends Control

@onready var full_name_edit:        LineEdit = $ColorRect/Panel/VBoxContainer/FullNameEdit
@onready var username_edit:         LineEdit = $ColorRect/Panel/VBoxContainer/UsernameEdit
@onready var password_edit:         LineEdit = $ColorRect/Panel/VBoxContainer/PasswordEdit
@onready var confirm_password_edit: LineEdit = $ColorRect/Panel/VBoxContainer/ConfirmPasswordEdit
@onready var error_label:           Label    = $ColorRect/Panel/VBoxContainer/ErrorLabel


func _ready() -> void:
	# Limpiar campos
	full_name_edit.text        = ""
	username_edit.text         = ""
	password_edit.text         = ""
	confirm_password_edit.text = ""
	error_label.text           = ""


# Botón "Crear perfil"
func _on_BtnCreate_pressed() -> void:
	var full_name: String        = full_name_edit.text.strip_edges()
	var username: String         = username_edit.text.strip_edges()
	var password: String         = password_edit.text.strip_edges()
	var confirm_password: String = confirm_password_edit.text.strip_edges()
	
	# Validar campos vacíos
	if full_name == "" or username == "" or password == "" or confirm_password == "":
		error_label.text = "Completa todos los campos."
		return
	
	# Validar coincidencia de contraseñas
	if password != confirm_password:
		error_label.text = "Las contraseñas no coinciden."
		return
	
	# Intentar registrar en el backend
	var ok: bool = ProgressManager.register_user(full_name, username, password)
	
	if not ok:
		# Puede ser nombre de usuario repetido o campo inválido
		if ProgressManager.users.has(username):
			error_label.text = "Ese usuario ya existe."
		else:
			error_label.text = "Datos inválidos."
		return
	
	# Registro exitoso: ir a selección de nivel (o menú)
	get_tree().change_scene_to_file("res://Menu/level_select.tscn")


# Botón "Volver"
func _on_BtnBack_pressed() -> void:
	get_tree().change_scene_to_file("res://Menu/menu.tscn")
