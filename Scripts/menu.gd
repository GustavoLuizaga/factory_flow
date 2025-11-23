extends Control

#@onready var username_modal: UsernameModal = $UsernameModal   # NUEVO
# NUEVO: escena del modal y variable para la instancia
var UsernameModalScene := preload("res://Menu/username_modal.tscn")
var username_modal: UsernameModal = null
# Panel de perfil
#var profile_panel_scene : PackedScene = preload("res://Menu/profile_panel.tscn")
# SOLO declaramos el tipo, sin asignar null
var profile_panel: Control

@onready var user_menu: MenuButton = $UserMenu
var dogica_font := preload("res://assets/scenes/dogica.ttf")

func _ready() -> void:
	_ensure_username()
	_setup_user_menu()
	
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
	# Actualizar el menú de usuario
	_update_user_menu_display()


# Configura el menú de usuario con el perfil actual
func _setup_user_menu() -> void:
	if not user_menu:
		return
	
	# Estilizar el botón del menú de usuario
	_style_user_menu_button()
	
	# Configurar el popup del menú
	var popup := user_menu.get_popup()
	popup.clear()
	popup.add_item("✏️ Editar Perfil", 0)
	
	# Estilizar el popup
	_style_popup_menu(popup)
	
	# Conectar la señal de selección
	if not popup.index_pressed.is_connected(_on_user_menu_item_selected):
		popup.index_pressed.connect(_on_user_menu_item_selected)
	
	# Actualizar la visualización
	_update_user_menu_display()


# Actualiza el botón del menú de usuario con los datos actuales
func _update_user_menu_display() -> void:
	if not user_menu:
		return
	
	if not ProgressManager.has_current_user():
		user_menu.text = "Usuario"
		user_menu.icon = null
		return
	
	var profile: Dictionary = ProgressManager.get_current_profile()
	var username: String = profile.get("username", "Usuario")
	
	# Actualizar texto
	user_menu.text = username
	
	# Actualizar icono (avatar)
	var avatar: Texture2D = ProgressManager.get_avatar_texture()
	if avatar:
		user_menu.icon = avatar


# Maneja la selección de opciones del menú de usuario
func _on_user_menu_item_selected(index: int) -> void:
	match index:
		0:  # Editar Perfil
			_open_edit_profile()


# Abre el modal para editar el perfil
func _open_edit_profile() -> void:
	# Crear una nueva instancia del modal
	username_modal = UsernameModalScene.instantiate()
	add_child(username_modal)
	username_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Conectar señal
	if not username_modal.username_confirmed.is_connected(_on_profile_updated):
		username_modal.username_confirmed.connect(_on_profile_updated)
	
	# Abrir en modo edición
	username_modal.open(true)


# Callback cuando se actualiza el perfil
func _on_profile_updated(new_username: String) -> void:
	print("Perfil actualizado:", new_username)
	_update_user_menu_display()


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Menu/level_select.tscn")


func _on_button_2_pressed() -> void:
	pass # Replace with function body.


func _on_button_3_pressed() -> void:
	get_tree().quit()


# Estiliza el botón del menú de usuario
func _style_user_menu_button() -> void:
	if not user_menu:
		return
	
	# Configurar fuente
	user_menu.add_theme_font_override("font", dogica_font)
	user_menu.add_theme_font_size_override("font_size", 18)
	user_menu.add_theme_color_override("font_color", Color.WHITE)
	
	# Sombra al texto
	user_menu.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	user_menu.add_theme_constant_override("shadow_offset_x", 2)
	user_menu.add_theme_constant_override("shadow_offset_y", 2)
	
	# Estilo normal
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	normal_style.border_color = Color(0.9, 0.85, 0.4)  # Dorado
	normal_style.set_border_width(SIDE_LEFT, 3)
	normal_style.set_border_width(SIDE_RIGHT, 3)
	normal_style.set_border_width(SIDE_TOP, 3)
	normal_style.set_border_width(SIDE_BOTTOM, 3)
	normal_style.set_corner_radius(CORNER_TOP_LEFT, 10)
	normal_style.set_corner_radius(CORNER_TOP_RIGHT, 10)
	normal_style.set_corner_radius(CORNER_BOTTOM_LEFT, 10)
	normal_style.set_corner_radius(CORNER_BOTTOM_RIGHT, 10)
	normal_style.shadow_color = Color(0, 0, 0, 0.5)
	normal_style.shadow_size = 5
	normal_style.content_margin_left = 12
	normal_style.content_margin_right = 12
	normal_style.content_margin_top = 8
	normal_style.content_margin_bottom = 8
	
	# Estilo hover
	var hover_style := normal_style.duplicate()
	hover_style.bg_color = Color(0.12, 0.12, 0.18, 0.98)
	hover_style.border_color = Color(1.0, 0.95, 0.5)  # Dorado brillante
	hover_style.shadow_size = 8
	
	# Estilo pressed
	var pressed_style := normal_style.duplicate()
	pressed_style.bg_color = Color(0.15, 0.15, 0.22, 1.0)
	pressed_style.border_color = Color(0.4, 1.0, 0.5)  # Verde
	
	user_menu.add_theme_stylebox_override("normal", normal_style)
	user_menu.add_theme_stylebox_override("hover", hover_style)
	user_menu.add_theme_stylebox_override("pressed", pressed_style)
	user_menu.add_theme_stylebox_override("focus", hover_style)
	
	# Ajustar tamaño del icono (avatar)
	user_menu.add_theme_constant_override("icon_max_width", 48)


# Estiliza el popup menu
func _style_popup_menu(popup: PopupMenu) -> void:
	if not popup:
		return
	
	# Fuente
	popup.add_theme_font_override("font", dogica_font)
	popup.add_theme_font_size_override("font_size", 16)
	popup.add_theme_color_override("font_color", Color.WHITE)
	
	# Colores de hover
	popup.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.2))
	
	# Estilo del panel
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.12, 0.97)
	panel_style.border_color = Color(0.9, 0.85, 0.4)
	panel_style.set_border_width(SIDE_LEFT, 3)
	panel_style.set_border_width(SIDE_RIGHT, 3)
	panel_style.set_border_width(SIDE_TOP, 3)
	panel_style.set_border_width(SIDE_BOTTOM, 3)
	panel_style.set_corner_radius(CORNER_TOP_LEFT, 8)
	panel_style.set_corner_radius(CORNER_TOP_RIGHT, 8)
	panel_style.set_corner_radius(CORNER_BOTTOM_LEFT, 8)
	panel_style.set_corner_radius(CORNER_BOTTOM_RIGHT, 8)
	panel_style.shadow_color = Color(0, 0, 0, 0.6)
	panel_style.shadow_size = 8
	panel_style.content_margin_left = 8
	panel_style.content_margin_right = 8
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8
	
	popup.add_theme_stylebox_override("panel", panel_style)
	
	# Estilo hover de items
	var hover_item := StyleBoxFlat.new()
	hover_item.bg_color = Color(0.2, 0.25, 0.3, 1.0)
	hover_item.set_corner_radius(CORNER_TOP_LEFT, 5)
	hover_item.set_corner_radius(CORNER_TOP_RIGHT, 5)
	hover_item.set_corner_radius(CORNER_BOTTOM_LEFT, 5)
	hover_item.set_corner_radius(CORNER_BOTTOM_RIGHT, 5)
	
	popup.add_theme_stylebox_override("hover", hover_item)
