extends Control
class_name UsernameModal

# Avisará al menú cuando ya tengamos usuario decidido
signal username_confirmed(username: String)

@onready var username_edit: LineEdit = $Panel/VBoxContainer/UsernameEdit
@onready var error_label: Label      = $Panel/VBoxContainer/ErrorLabel
@onready var title_label: Label      = $Panel/VBoxContainer/TitleLabel
@onready var char_counter_label: Label = $Panel/VBoxContainer/CharCounterLabel
#@onready var trophy_icon: TextureRect = $Panel/VBoxContainer/TrophyIcon
@onready var ok_button: Button       = $Panel/VBoxContainer/HBoxContainer/OkButton
@onready var random_button: Button   = $Panel/VBoxContainer/HBoxContainer/RandomButton
@onready var avatar_rect: TextureRect  = $Panel/VBoxContainer/CenterContainer/AvatarRect
@onready var file_dialog: FileDialog   = $FileDialog
@onready var select_avatar_button: Button = $Panel/VBoxContainer/SelectAvatarButton

const DEFAULT_AVATAR: Texture2D = preload("res://assets/images/avatar_default.png")

# Ruta del avatar elegido para este modal (user://...)
var _selected_avatar_path: String = ""

# Modo de edición: si es true, estamos editando un perfil existente
var is_edit_mode: bool = false

func _ready() -> void:
	# Empieza oculto; lo abrirá el menú si hace falta
	visible = false
	# Bloquear clicks al fondo mientras el modal está visible
	mouse_filter = Control.MOUSE_FILTER_STOP
	# IMPORTANTE: este nodo sigue procesando aunque el árbol esté en pausa
	#pause_mode = Node.PAUSE_MODE_PROCESS
	
	# Mostrar avatar por defecto al abrir el modal
	if avatar_rect:
		avatar_rect.texture = DEFAULT_AVATAR
	# ESTILOS VISUALES
	
	_setup_panel_style()
	_setup_text_style()
	_setup_buttons_style()
	
	# Conectar señal para actualizar contador de caracteres
	if username_edit:
		username_edit.text_changed.connect(_on_username_text_changed)

# Llamar a esto para mostrar el modal
# edit_mode: si es true, carga los datos del perfil actual para editarlos
func open(edit_mode: bool = false) -> void:
	is_edit_mode = edit_mode
	visible = true
	
	if error_label:
		error_label.text = ""
	
	if is_edit_mode:
		# Modo edición: cargar datos del perfil actual
		var profile := ProgressManager.get_current_profile()
		
		# Cargar nombre actual
		if username_edit:
			username_edit.text = profile.get("username", "")
			username_edit.grab_focus()
		
		# Cargar avatar actual
		if avatar_rect:
			avatar_rect.texture = ProgressManager.get_avatar_texture()
		
		# Guardar la ruta del avatar actual
		_selected_avatar_path = profile.get("avatar_path", "")
		
		# Cambiar título
		if title_label:
			title_label.text = "EDITAR PERFIL"
		
		# Cambiar texto del botón OK
		if ok_button:
			ok_button.text = "Guardar Cambios"
		
		# Ocultar botón de nombre aleatorio en modo edición
		if random_button:
			random_button.visible = false
		
		# Mostrar cuántos cambios quedan
		var remaining := ProgressManager.get_remaining_name_changes()
		if char_counter_label:
			if remaining > 0:
				char_counter_label.text = "Cambios restantes: %d/5" % remaining
				char_counter_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
			else:
				char_counter_label.text = "Sin cambios disponibles (0/5)"
				char_counter_label.add_theme_color_override("font_color", Color(1, 0.35, 0.35))
				# Deshabilitar edición si no quedan cambios
				if username_edit:
					username_edit.editable = false
				if ok_button:
					ok_button.disabled = true
	else:
		# Modo creación: limpiar campos
		if username_edit:
			username_edit.text = ""
			username_edit.grab_focus()
		
		if avatar_rect:
			avatar_rect.texture = DEFAULT_AVATAR
		
		_selected_avatar_path = ""
		
		if title_label:
			title_label.text = "BIENVENIDO/A!"
		
		if ok_button:
			ok_button.text = "Continuar"
		
		if random_button:
			random_button.visible = true
		
		# Ocultar contador en modo creación
		if char_counter_label:
			char_counter_label.visible = false


func _close() -> void:
	visible = false
	get_tree().paused = false
	queue_free()


func _on_OkButton_pressed() -> void:
	# Usa el nombre escrito (si está vacío, el backend generará uno)
	_confirm_username(username_edit.text)


func _on_RandomButton_pressed() -> void:
	# Fuerza que se genere un nombre por defecto
	_confirm_username("")
	

# Lógica común para ambos botones que llama al backend
func _confirm_username(raw_name: String) -> void:
	if is_edit_mode:
		# Modo edición: actualizar perfil existente
		raw_name = raw_name.strip_edges()
		
		# Validar que no esté vacío
		if raw_name == "":
			error_label.text = "El nombre no puede estar vacío."
			return
		
		# Validar longitud máxima
		if raw_name.length() > 6:
			error_label.text = "Máximo 6 caracteres."
			return
		
		# Intentar actualizar el nombre
		var success := ProgressManager.update_username(raw_name)
		
		if not success:
			# Verificar si fue por límite de cambios o nombre duplicado
			if ProgressManager.get_remaining_name_changes() == 0:
				error_label.text = "Límite de cambios alcanzado."
			else:
				# El nombre ya está en uso
				error_label.text = "Ese nombre ya está en uso."
			return
		
		# Si se eligió un nuevo avatar, actualizarlo
		if _selected_avatar_path != "":
			ProgressManager.set_avatar(_selected_avatar_path)
		
		# Emitir señal con el nombre actualizado
		username_confirmed.emit(raw_name)
		_close()
	else:
		# Modo creación: crear nuevo perfil
		# 1) El backend asegura que haya usuario (crea o selecciona)
		var final_name := ProgressManager.ensure_simple_user(raw_name)

		if final_name == "":
			# Caso muy raro: algo falló guardando
			error_label.text = "No se pudo crear el perfil."
			return

		# 2) Si se eligió un avatar, lo guardamos en el perfil
		if _selected_avatar_path != "":
			ProgressManager.set_avatar(_selected_avatar_path)
			
		# 3) Avisamos al menu que el usuario ya esta listo
		username_confirmed.emit(final_name)
		_close()

#=ESTILOS VISUALES
# Panel tipo “cartel de nivel superado”
func _setup_panel_style() -> void:
	var panel := $Panel

	# StyleBox del panel
	var sb := StyleBoxFlat.new()

	# Más separación general
	var vb := $Panel/VBoxContainer
	vb.add_theme_constant_override("separation", 28)      # separa elementos
	vb.add_theme_constant_override("top_padding", 35)     # padding arriba
	vb.add_theme_constant_override("bottom_padding", 35)  # padding abajo

	
	# Fondo azul oscuro
	sb.bg_color = Color(0.08, 0.14, 0.32, 0.97)

	# Borde tipo madera (marrón)
	sb.border_color = Color(0.50, 0.28, 0.08, 1.0)
	sb.border_width_left = 18
	sb.border_width_top = 18
	sb.border_width_right = 18
	sb.border_width_bottom = 18

	# Esquinas redondeadas como marco
	sb.corner_radius_top_left = 16
	sb.corner_radius_top_right = 16
	sb.corner_radius_bottom_left = 16
	sb.corner_radius_bottom_right = 16

	# Pequeña sombra interior para dar profundidad
	sb.shadow_size = 8
	sb.shadow_color = Color(0, 0, 0, 0.35)

	panel.add_theme_stylebox_override("panel", sb)

# Textos (título, error, placeholder)
func _setup_text_style() -> void:
	# Título tipo “¡NIVEL SUPERADO!”
	if title_label:
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.add_theme_font_size_override("font_size", 34)
		# Naranja/dorado
		title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
		# Contorno negro
		title_label.add_theme_constant_override("outline_size", 3)
		title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))

	# Mensaje de error abajo
	if error_label:
		error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		error_label.add_theme_font_size_override("font_size", 18)
		error_label.add_theme_color_override("font_color", Color(1, 0.35, 0.35))

	# LineEdit para el username
	if username_edit:
		username_edit.add_theme_font_size_override("font_size", 22)
		username_edit.add_theme_color_override("font_color", Color(1, 1, 1))
		username_edit.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		username_edit.add_theme_constant_override("outline_size", 2)
		username_edit.placeholder_text = "Escribe tu nombre de jugador..."
		username_edit.max_length = 10  # <- Límite de 10 caracteres

			# --- Hacer el campo más grueso ---
		username_edit.custom_minimum_size = Vector2(0, 48)   # ← altura del campo
		# Puedes probar 50, 55 o 60 si lo quieres aún más grande

		# Grosor del borde (opcional)
		var sbl:= StyleBoxFlat.new()
		sbl.bg_color = Color(0.04, 0.08, 0.20, 0.95)
		sbl.border_color = Color(0.9, 0.9, 0.9, 0.8)
		sbl.border_width_left = 3
		sbl.border_width_top = 3
		sbl.border_width_right = 3
		sbl.border_width_bottom = 3
		sbl.corner_radius_top_left = 10
		sbl.corner_radius_top_right = 10
		sbl.corner_radius_bottom_left = 10
		sbl.corner_radius_bottom_right = 10

		username_edit.add_theme_stylebox_override("normal", sbl)
		username_edit.add_theme_stylebox_override("focus", sbl)

		# Fondo del LineEdit
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.04, 0.08, 0.20, 0.95)
		sb.border_color = Color(0.9, 0.9, 0.9, 0.8)
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.corner_radius_top_left = 8
		sb.corner_radius_top_right = 8
		sb.corner_radius_bottom_left = 8
		sb.corner_radius_bottom_right = 8
		username_edit.add_theme_stylebox_override("normal", sb)
		username_edit.add_theme_stylebox_override("focus", sb)

	# Icono de trofeo (por si quieres tocar algo de tamaño)
	#if trophy_icon:
	#	trophy_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	#	trophy_icon.custom_minimum_size = Vector2(96, 96)

# Botones tipo “VOLVER AL MENÚ / SIGUIENTE NIVEL”
func _setup_buttons_style() -> void:
	if ok_button:
		_style_main_button(ok_button, Color(0.10, 0.70, 0.30))      # azul
	if random_button:
		_style_main_button(random_button, Color(0.16, 0.55, 1.0))  # verde
	# --- Botón de SUBIR FOTO (naranja) ---
	#if select_avatar_button:
	#	_style_main_button(select_avatar_button, Color(1.0, 0.55, 0.15))  # naranja

func _style_main_button(btn: Button, base_color: Color) -> void:
	# Estado normal
	var normal := StyleBoxFlat.new()
	normal.bg_color = base_color
	normal.corner_radius_top_left = 12
	normal.corner_radius_top_right = 12
	normal.corner_radius_bottom_left = 12
	normal.corner_radius_bottom_right = 12
	normal.border_color = Color(0, 0, 0, 0.6)
	normal.border_width_left = 3
	normal.border_width_top = 3
	normal.border_width_right = 3
	normal.border_width_bottom = 3

	# Hover
	var hover := normal.duplicate()
	hover.bg_color = base_color.lightened(0.15)

	# Presionado
	var pressed := normal.duplicate()
	pressed.bg_color = base_color.darkened(0.18)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)

	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	btn.add_theme_constant_override("outline_size", 2)

	# Tamaño mínimo tipo botón grande
	btn.custom_minimum_size = Vector2(240, 64)



func _on_SelectAvatarButton_pressed() -> void:
	# Abrir el FileDialog para elegir imagen
	if file_dialog:
		file_dialog.popup_centered()

#cuando el usuario elige su imagen
func _on_FileDialog_file_selected(path: String) -> void:
	var img := Image.new()
	var err := img.load(path)
	if err != OK:
		error_label.text = "No se pudo cargar la imagen."
		return

	# Aseguramos carpeta user://avatars
	var dir := DirAccess.open("user://")
	if dir and not dir.dir_exists("avatars"):
		dir.make_dir("avatars")

	# Guardamos una copia en user:// (para que el apk no dependa de rutas externas)
	var filename := "avatar_%d.png" % int(Time.get_unix_time_from_system())
	var save_path := "user://avatars/%s" % filename

	var save_err := img.save_png(save_path)
	if save_err != OK:
		error_label.text = "No se pudo guardar el avatar."
		return

	# Mostrar en el TextureRect
	var tex := ImageTexture.create_from_image(img)
	if avatar_rect:
		avatar_rect.texture = tex

	# Recordar la ruta para guardarla cuando se confirme el usuario
	_selected_avatar_path = save_path


# Actualiza el contador de caracteres mientras el usuario escribe
func _on_username_text_changed(new_text: String) -> void:
	if not char_counter_label:
		return
	
	if is_edit_mode:
		# En modo edición, mostrar caracteres usados
		var remaining := ProgressManager.get_remaining_name_changes()
		if remaining > 0:
			char_counter_label.text = "Cambios restantes: %d/5 | %d/10 caracteres" % [remaining, new_text.length()]
		else:
			char_counter_label.text = "Sin cambios disponibles (0/5)"
	else:
		# En modo creación, solo mostrar caracteres
		char_counter_label.text = "%d/10 caracteres" % new_text.length()
		char_counter_label.visible = true
		
		if new_text.length() >= 10:
			char_counter_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
		else:
			char_counter_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
