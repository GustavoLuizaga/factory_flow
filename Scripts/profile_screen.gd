extends Control

const TOTAL_LEVELS := 3  # cambia a 2, 3, etc. según tu juego
const DEFAULT_AVATAR: Texture2D = preload("res://assets/images/avatar_default.png")

@onready var avatar_rect: TextureRect   = $Panel/VBoxContainer/CenterContainer/AvatarRect
@onready var username_label: Label      = $Panel/VBoxContainer/UsernameLabel
@onready var progress_label: Label      = $Panel/VBoxContainer/ProgressLabel
@onready var extra_info_label: Label    = $Panel/VBoxContainer/ExtraInfoLabel
@onready var title_label: Label         = $Panel/VBoxContainer/TitleLabel
@onready var back_button: Button        = $Panel/VBoxContainer/BackButton

func _ready() -> void:
	_setup_panel_style()
	_setup_text_style()
	_setup_button_style()

	_update_profile_view()


func _update_profile_view() -> void:
	var profile := ProgressManager.get_current_profile()

	# Si por alguna razón no hay usuario actual
	if profile.is_empty():
		username_label.text = "Usuario: (sin perfil)"
		progress_label.text = "Nivel máximo alcanzado: 0 de %d" % TOTAL_LEVELS
		extra_info_label.text = "Perfil no inicializado."
		avatar_rect.texture = DEFAULT_AVATAR
		return

	# Nombre
	var username := String(profile.get("username", "???"))
	username_label.text = "Usuario: %s" % username

	# Progreso
	var highest := int(profile.get("highest_unlocked", 1))
	progress_label.text = "Nivel máximo alcanzado: %d de %d" % [highest, TOTAL_LEVELS]

	# Fecha de creación
	var created_ts := int(profile.get("created_at", Time.get_unix_time_from_system()))
	var dt := Time.get_datetime_string_from_unix_time(created_ts)
	extra_info_label.text = "Perfil creado: %s" % dt

	# Avatar
	var avatar_path := ProgressManager.get_avatar_path()
	if avatar_path != "":
		var img := Image.new()
		if img.load(avatar_path) == OK:
			var tex := ImageTexture.create_from_image(img)
			avatar_rect.texture = tex
		else:
			avatar_rect.texture = DEFAULT_AVATAR
	else:
		avatar_rect.texture = DEFAULT_AVATAR


func _on_BackButton_pressed() -> void:
	get_tree().change_scene_to_file("res://Menu/menu.tscn")


# -------------------
# ESTILOS VISUALES
# -------------------

func _setup_panel_style() -> void:
	var panel := $Panel
	var sb := StyleBoxFlat.new()

	# Fondo azul oscuro
	sb.bg_color = Color(0.08, 0.14, 0.32, 0.97)

	# Borde tipo marco madera
	sb.border_color = Color(0.50, 0.28, 0.08, 1.0)
	sb.border_width_left = 18
	sb.border_width_top = 18
	sb.border_width_right = 18
	sb.border_width_bottom = 18

	sb.corner_radius_top_left = 16
	sb.corner_radius_top_right = 16
	sb.corner_radius_bottom_left = 16
	sb.corner_radius_bottom_right = 16

	sb.shadow_size = 8
	sb.shadow_color = Color(0, 0, 0, 0.35)

	panel.add_theme_stylebox_override("panel", sb)

	# Separación interna del VBox
	var vb := $Panel/VBoxContainer
	vb.add_theme_constant_override("separation", 22)
	vb.add_theme_constant_override("top_padding", 30)
	vb.add_theme_constant_override("bottom_padding", 30)


func _setup_text_style() -> void:
	# Título
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 34)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	title_label.add_theme_constant_override("outline_size", 3)
	title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))

	# Labels de info
	for lbl in [username_label, progress_label, extra_info_label]:
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1))

	# Avatar
	avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar_rect.custom_minimum_size = Vector2(96, 96)


func _setup_button_style() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.16, 0.55, 1.0)
	normal.corner_radius_top_left = 12
	normal.corner_radius_top_right = 12
	normal.corner_radius_bottom_left = 12
	normal.corner_radius_bottom_right = 12
	normal.border_color = Color(0, 0, 0, 0.6)
	normal.border_width_left = 3
	normal.border_width_top = 3
	normal.border_width_right = 3
	normal.border_width_bottom = 3

	var hover := normal.duplicate()
	hover.bg_color = normal.bg_color.lightened(0.15)

	var pressed := normal.duplicate()
	pressed.bg_color = normal.bg_color.darkened(0.18)

	back_button.add_theme_stylebox_override("normal", normal)
	back_button.add_theme_stylebox_override("hover", hover)
	back_button.add_theme_stylebox_override("pressed", pressed)
	back_button.add_theme_stylebox_override("focus", hover)

	back_button.add_theme_font_size_override("font_size", 22)
	back_button.add_theme_color_override("font_color", Color(1, 1, 1))
	back_button.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	back_button.add_theme_constant_override("outline_size", 2)
	back_button.custom_minimum_size = Vector2(260, 64)
