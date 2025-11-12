extends CanvasLayer

## Menú de pausa funcional con opciones de reanudar, reiniciar, volumen y salir

signal pause_toggled(is_paused: bool)

@onready var panel: Panel = $Panel
@onready var vbox: VBoxContainer = $Panel/VBoxContainer

var is_paused: bool = false
var audio_bus_index: int = -1

# Botones
var resume_btn: Button
var restart_btn: Button
var volume_up_btn: Button
var volume_down_btn: Button
var exit_btn: Button
var volume_label: Label

# Referencia a la fuente
var dogica_font = preload("res://assets/scenes/dogica.ttf")

# Música de fondo
var background_music: AudioStreamPlayer = null


func _ready() -> void:
	# Buscar el AudioBusLayout
	audio_bus_index = AudioServer.get_bus_index("Master")
	if audio_bus_index == -1:
		print("⚠️ No se encontró AudioBus 'Master', usando el predeterminado")
		audio_bus_index = 0
	
	# Ocultar inicialmente
	visible = false
	
	# Estilizar el panel
	if panel:
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
		panel_style.border_color = Color.WHITE
		panel_style.set_border_width(SIDE_LEFT, 3)
		panel_style.set_border_width(SIDE_RIGHT, 3)
		panel_style.set_border_width(SIDE_TOP, 3)
		panel_style.set_border_width(SIDE_BOTTOM, 3)
		panel.add_theme_stylebox_override("panel", panel_style)
	
	# Crear los botones
	create_buttons()
	
	# Inicializar música de fondo
	setup_background_music()
	
	# Conectar entrada de teclado
	get_tree().paused = false
	print("✅ PauseMenu inicializado")


func _input(event: InputEvent) -> void:
	# Presionar ESC para pausar/reanudar
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			toggle_pause()
			get_tree().root.set_input_as_handled()


func create_buttons() -> void:
	# Verificar que el contenedor existe
	if not vbox:
		print("❌ ERROR: VBoxContainer no encontrado")
		return
	
	# Limpiar contenedor
	for child in vbox.get_children():
		child.queue_free()
	
	# Etiqueta de "Pausa"
	var title = Label.new()
	title.text = "PAUSA"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_font_override("font", dogica_font)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Espacio
	var spacer = Control.new()
	spacer.set_custom_minimum_size(Vector2(0, 10))
	vbox.add_child(spacer)
	
	# Botón Reanudar
	resume_btn = create_button("Reanudar")
	resume_btn.pressed.connect(_on_resume_pressed)
	vbox.add_child(resume_btn)
	
	# Botón Reiniciar Nivel
	restart_btn = create_button("Reiniciar Nivel")
	restart_btn.pressed.connect(_on_restart_pressed)
	vbox.add_child(restart_btn)
	
	# Control de Volumen
	var volume_container = HBoxContainer.new()
	volume_container.alignment = BoxContainer.ALIGNMENT_CENTER
	volume_container.add_theme_constant_override("separation", 10)
	
	volume_down_btn = create_button("🔊 -", 60)
	volume_down_btn.pressed.connect(_on_volume_down)
	volume_container.add_child(volume_down_btn)
	
	volume_label = Label.new()
	volume_label.text = "Volumen: 100%"
	volume_label.add_theme_font_size_override("font_size", 16)
	volume_label.add_theme_font_override("font", dogica_font)
	volume_label.add_theme_color_override("font_color", Color.WHITE)
	volume_label.custom_minimum_size = Vector2(150, 40)
	volume_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	volume_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	volume_container.add_child(volume_label)
	
	volume_up_btn = create_button("🔊 +", 60)
	volume_up_btn.pressed.connect(_on_volume_up)
	volume_container.add_child(volume_up_btn)
	
	vbox.add_child(volume_container)
	
	# Botón Salir al Menú
	exit_btn = create_button("Salir al Menú")
	exit_btn.pressed.connect(_on_exit_pressed)
	vbox.add_child(exit_btn)
	
	print("✅ Botones del menú de pausa creados correctamente")


func create_button(text: String, width: int = 200) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(width, 50)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_font_override("font", dogica_font)
	btn.add_theme_color_override("font_color", Color.WHITE)
	
	# Crear un fondo con color
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.2, 0.2, 0.2, 0.9)
	stylebox.border_color = Color.WHITE
	stylebox.set_border_width(SIDE_LEFT, 2)
	stylebox.set_border_width(SIDE_RIGHT, 2)
	stylebox.set_border_width(SIDE_TOP, 2)
	stylebox.set_border_width(SIDE_BOTTOM, 2)
	stylebox.set_corner_radius(CORNER_TOP_LEFT, 5)
	stylebox.set_corner_radius(CORNER_TOP_RIGHT, 5)
	stylebox.set_corner_radius(CORNER_BOTTOM_LEFT, 5)
	stylebox.set_corner_radius(CORNER_BOTTOM_RIGHT, 5)
	
	btn.add_theme_stylebox_override("normal", stylebox)
	
	# Estilo al pasar el ratón
	var stylebox_hover = StyleBoxFlat.new()
	stylebox_hover.bg_color = Color(0.3, 0.3, 0.3, 1.0)
	stylebox_hover.border_color = Color.YELLOW
	stylebox_hover.set_border_width(SIDE_LEFT, 2)
	stylebox_hover.set_border_width(SIDE_RIGHT, 2)
	stylebox_hover.set_border_width(SIDE_TOP, 2)
	stylebox_hover.set_border_width(SIDE_BOTTOM, 2)
	stylebox_hover.set_corner_radius(CORNER_TOP_LEFT, 5)
	stylebox_hover.set_corner_radius(CORNER_TOP_RIGHT, 5)
	stylebox_hover.set_corner_radius(CORNER_BOTTOM_LEFT, 5)
	stylebox_hover.set_corner_radius(CORNER_BOTTOM_RIGHT, 5)
	
	btn.add_theme_stylebox_override("hover", stylebox_hover)
	
	# Estilo presionado
	var stylebox_pressed = StyleBoxFlat.new()
	stylebox_pressed.bg_color = Color(0.4, 0.4, 0.4, 1.0)
	stylebox_pressed.border_color = Color.GREEN
	stylebox_pressed.set_border_width(SIDE_LEFT, 2)
	stylebox_pressed.set_border_width(SIDE_RIGHT, 2)
	stylebox_pressed.set_border_width(SIDE_TOP, 2)
	stylebox_pressed.set_border_width(SIDE_BOTTOM, 2)
	stylebox_pressed.set_corner_radius(CORNER_TOP_LEFT, 5)
	stylebox_pressed.set_corner_radius(CORNER_TOP_RIGHT, 5)
	stylebox_pressed.set_corner_radius(CORNER_BOTTOM_LEFT, 5)
	stylebox_pressed.set_corner_radius(CORNER_BOTTOM_RIGHT, 5)
	
	btn.add_theme_stylebox_override("pressed", stylebox_pressed)
	
	return btn


func toggle_pause() -> void:
	is_paused = !is_paused
	visible = is_paused
	get_tree().paused = is_paused
	pause_toggled.emit(is_paused)
	
	# Pausar/Reanudar música de fondo
	if background_music:
		if is_paused:
			background_music.stream_paused = true
		else:
			background_music.stream_paused = false
	
	if is_paused:
		print("⏸️ PAUSA activada")
		# Procesar eventos mientras está pausado
		get_tree().root.set_input_as_handled()
	else:
		print("▶️ Juego reanudado")
		get_tree().root.set_input_as_handled()


func _on_resume_pressed() -> void:
	print("🎮 Botón Reanudar presionado")
	toggle_pause()


func _on_restart_pressed() -> void:
	print("🔄 Botón Reiniciar presionado")
	get_tree().paused = false
	
	# Obtener el nombre de la escena actual
	var current_scene = get_tree().current_scene.scene_file_path
	get_tree().reload_current_scene()
	print("🔄 Reiniciando nivel: ", current_scene)


func _on_exit_pressed() -> void:
	print("🚪 Botón Salir presionado")
	get_tree().paused = false
	
	# Volver al menú principal
	get_tree().change_scene_to_file("res://Menu/menu.tscn")
	print("🚪 Saliendo al menú principal")


func _on_volume_up() -> void:
	print("🔊+ Aumentar volumen")
	var current_db = AudioServer.get_bus_volume_db(audio_bus_index)
	var current_volume = db_to_linear(current_db)
	
	current_volume = min(current_volume + 0.1, 1.0)
	
	AudioServer.set_bus_volume_db(audio_bus_index, linear_to_db(current_volume))
	
	var percentage = int(current_volume * 100)
	volume_label.text = "Volumen: %d%%" % percentage
	print("🔊 Volumen: ", percentage, "%")


func _on_volume_down() -> void:
	print("🔊- Disminuir volumen")
	var current_db = AudioServer.get_bus_volume_db(audio_bus_index)
	var current_volume = db_to_linear(current_db)
	
	current_volume = max(current_volume - 0.1, 0.0)
	
	AudioServer.set_bus_volume_db(audio_bus_index, linear_to_db(current_volume))
	
	var percentage = int(current_volume * 100)
	volume_label.text = "Volumen: %d%%" % percentage
	print("🔊 Volumen: ", percentage, "%")


func get_current_volume() -> int:
	var current_volume = db_to_linear(AudioServer.get_bus_volume_db(audio_bus_index))
	return int(current_volume * 100)


func setup_background_music() -> void:
	# Buscar si ya existe un reproductor de música en la escena
	var current_scene = get_tree().current_scene
	if not current_scene:
		print("❌ No se encontró la escena actual")
		return
	
	# Buscar un AudioStreamPlayer existente
	var existing_player = current_scene.find_child("BackgroundMusic", true, false)
	if existing_player and existing_player is AudioStreamPlayer:
		background_music = existing_player
		print("✅ Música de fondo encontrada en la escena")
		return
	
	# Si no existe, crear uno nuevo usando call_deferred para evitar conflictos
	background_music = AudioStreamPlayer.new()
	background_music.name = "BackgroundMusic"
	background_music.bus = "Master"
	
	# Cargar la música
	var music_resource = preload("res://assets/sounds/main_theme.mp3")
	if music_resource:
		background_music.stream = music_resource
		background_music.bus = "Master"
		
		# Usar call_deferred para agregar el nodo después de que todo esté listo
		current_scene.add_child.call_deferred(background_music)
		background_music.play.call_deferred()
		print("✅ Música de fondo iniciada: main_theme.mp3")
	else:
		print("❌ No se pudo cargar main_theme.mp3")
