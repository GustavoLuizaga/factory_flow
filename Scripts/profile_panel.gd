extends Control
class_name ProfilePanel

# Referencias a los nodos de la UI
@onready var login_container: VBoxContainer    = $ColorRect/Panel/VBoxContainer/LoginContainer
@onready var register_container: VBoxContainer = $ColorRect/Panel/VBoxContainer/RegisterContainer
@onready var login_username: LineEdit      = $ColorRect/Panel/VBoxContainer/LoginContainer/LoginUsername
@onready var login_password: LineEdit  = $ColorRect/Panel/VBoxContainer/LoginContainer/LoginPassword
@onready var register_fullname: LineEdit         = $ColorRect/Panel/VBoxContainer/RegisterContainer/RegisterFullname
@onready var register_username: LineEdit   = $ColorRect/Panel/VBoxContainer/RegisterContainer/RegisterUsername
@onready var register_password: LineEdit         = $ColorRect/Panel/VBoxContainer/RegisterContainer/RegisterPassword
@onready var register_confirm_password: LineEdit = $ColorRect/Panel/VBoxContainer/RegisterContainer/RegisterConfirmPassword

@onready var error_label: Label            = $ColorRect/Panel/VBoxContainer/ErrorLabel

func _ready() -> void:
	# El panel empieza oculto
	visible = false
	_show_login()

# -------------------------
# Métodos para abrir el panel
# -------------------------

# El menú llamará a esto: mode = "login" o "register"
func open_as(mode: String) -> void:
	visible = true
	get_tree().paused = true
	error_label.text = ""

	if mode == "login":
		_show_login()
	else:
		_show_register()

func _show_login() -> void:
	login_container.visible = true
	register_container.visible = false

func _show_register() -> void:
	login_container.visible = false
	register_container.visible = true

# -------------------------
# Callbacks de botones
# (conecta en el editor)
# -------------------------

func _on_login_tab_button_pressed() -> void:
	_show_login()

func _on_register_tab_button_pressed() -> void:
	_show_register()

func _on_close_button_pressed() -> void:
	visible = false
	get_tree().paused = false

func _on_login_button_pressed() -> void:
	# Leemos usuario y contraseña desde los LineEdit
	var username: String = login_username.text.strip_edges()
	var password: String = login_password.text

	# Validación básica
	if username == "" or password == "":
		error_label.text = "Ingresa usuario y contraseña."
		return

	# Llamamos al ProgressManager con (username, password)
	var ok: bool = ProgressManager.login(username, password)

	if not ok:
		error_label.text = "Usuario o contraseña incorrectos."
		return

	# Si todo va bien, cerramos el panel
	_on_close_button_pressed()

func _on_register_button_pressed() -> void:
	# Leemos los datos del formulario de registro
	var full_name: String = register_fullname.text.strip_edges()
	var username: String = register_username.text.strip_edges()
	var password: String = register_password.text
	var confirm: String = register_confirm_password.text

	# Validación básica
	if full_name == "" or username == "" or password == "" or confirm == "":
		error_label.text = "Completa todos los campos."
		return
	if password != confirm:
		error_label.text = "Las contraseñas no coinciden."
		return
		
	# Registrar usuario en ProgressManager
	var ok: bool = ProgressManager.register_user(full_name, username, password)
	if not ok:
		error_label.text = "El usuario ya existe o los datos no son válidos."
		return

	# Si todo bien, cerramos el panel
	_on_close_button_pressed()
