extends Node2D

## Level 3 - Fusiones Definitivas (Ultimate Fusions)

@onready var grid: Grid = $Grid
@onready var top_menu: CanvasLayer = $TopMenu
@onready var camera: Camera2D = $Camera2D
@onready var money_display: CanvasLayer = null  # Se crea dinámicamente
@export var congratulation_scene: PackedScene = preload("res://level_modal/level_congratulation.tscn")

var hub_objective_scene: PackedScene = preload("res://ui/barra_objetivos/hub_objetive.tscn")
var hub_objective: Node2D

var delete_mode: bool = false

# Temporizador para Nivel 3
var tiempo_total: float = 60.0  # Valor por defecto si falla JSON
var tiempo_restante: float = 60.0
var timer_label: Label

func _ready() -> void:
	print("=== Level 3 iniciado (Fusiones Definitivas) ===")
	
	# Cargar tiempo límite desde JSON
	load_level_time_limit(3)
	
	setup_camera()
	center_grid()
	setup_material_spawners()  # Agregar spawners estratégicos
	
	##NUEVO
	ObjectiveManager.reset_for_level(3)   # ← nivel 3
	setup_objective_hub_ui()              # ← crea HUD

	add_super_machine_button()  # Agregar botón de super-máquina
	add_ultimate_machine_button()  # NUEVO: Agregar botón de ultimate-máquina
	
	# Inicializar sistema de economía
	if EconomyManager:
		EconomyManager.initialize_for_level(3)
		add_money_display()

		if not EconomyManager.game_over_no_money.is_connected(_on_game_over_no_money):
			EconomyManager.game_over_no_money.connect(_on_game_over_no_money)

	
	# Conectar la señal del modo borrar
	if top_menu:
		top_menu.delete_mode_changed.connect(_on_delete_mode_changed)
	
	# Configurar temporizador
	setup_timer()
	if not ObjectiveManager.all_objectives_completed.is_connected(_on_level_won):
		ObjectiveManager.all_objectives_completed.connect(_on_level_won)

## Callback cuando se completan todos los objetivos (GANASTE)
func _on_level_won() -> void:
	print("NIVEL 3 COMPLETADO!")
	
	# 1. Evitar que el tiempo siga corriendo o que pierdas mientras celebras
	tiempo_restante = 9999 # Truco simple para que no salte el timeout
	
	# 2. Crear el modal
	if congratulation_scene:
		var modal = congratulation_scene.instantiate()
		
		# 3. Conectar la señal del botón "Volver al menú"
		if modal.has_signal("menu_requested"):
			modal.menu_requested.connect(_on_return_to_menu)
		
		# 4. Mostrarlo
		add_child(modal)
		
		# 5. Pausar el juego (el modal debe tener process_mode = WHEN_PAUSED)
		get_tree().paused = true
	else:
		print("❌ Error: No se ha asignado la escena congratulation_scene")

## Callback para volver al menú principal
func _on_return_to_menu() -> void:
	print("🏠 Volviendo al Menú Principal...")
	# Asegúrate de que esta ruta exista
	get_tree().change_scene_to_file("res://Menu/menu.tscn")
func _process(delta: float) -> void:
	# Actualizar temporizador
	if tiempo_restante > 0:
		tiempo_restante -= delta
		if tiempo_restante <= 0:
			tiempo_restante = 0
			show_timeout_message()
		update_timer_display()

## Configura el temporizador y su display
func setup_timer() -> void:
	timer_label = Label.new()
	timer_label.add_theme_font_size_override("font_size", 32)
	timer_label.add_theme_color_override("font_color", Color.WHITE)
	timer_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	timer_label.add_theme_constant_override("shadow_offset_x", 2)
	timer_label.add_theme_constant_override("shadow_offset_y", 2)
	timer_label.position = Vector2(50, 50)  # Esquina superior izquierda
	update_timer_display()
	
	# Añadir al top_menu para que esté sobre la UI
	if top_menu:
		top_menu.add_child(timer_label)
	else:
		add_child(timer_label)  # Fallback si no hay top_menu
	
	print("⏱️ Temporizador configurado para Nivel 3 con tiempo límite:", tiempo_total, "segundos")


## Carga el tiempo límite del nivel desde el JSON
func load_level_time_limit(nivel_num: int) -> void:
	var json_path = "res://database/game_data.json"
	
	if not FileAccess.file_exists(json_path):
		print("❌ JSON no encontrado, usando tiempo por defecto:", tiempo_total, "segundos")
		return
	
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		print("❌ Error al abrir JSON, usando tiempo por defecto:", tiempo_total, "segundos")
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error != OK:
		print("❌ Error al parsear JSON, usando tiempo por defecto:", tiempo_total, "segundos")
		return
	
	var data = json.data
	
	if data.has("niveles"):
		for nivel in data["niveles"]:
			if nivel["numero"] == nivel_num:
				if nivel.has("tiempo_limite_segundos"):
					tiempo_total = float(nivel["tiempo_limite_segundos"])
					tiempo_restante = tiempo_total
					print("✅ Tiempo límite cargado desde JSON: ", tiempo_total, "segundos (", tiempo_total/60, " minutos)")
					return
	
	print("⚠️ No se encontró tiempo_limite_segundos para nivel", nivel_num, ", usando valor por defecto:", tiempo_total, "segundos")

## Actualiza el display del temporizador
func update_timer_display() -> void:
	if timer_label:
		var minutos = int(tiempo_restante / 60)
		var segundos = int(tiempo_restante) % 60
		timer_label.text = "Tiempo: %02d:%02d" % [minutos, segundos]
		
		# Cambiar color cuando queden menos de 10 segundos
		if tiempo_restante <= 10:
			timer_label.add_theme_color_override("font_color", Color.RED)
		else:
			timer_label.add_theme_color_override("font_color", Color.WHITE)

## Muestra el mensaje de tiempo agotado LEO aqui puedes agregar tu menu de perdiste cuando el tiempo se termina
func show_timeout_message() -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "⏰ Tiempo Agotado"
	dialog.dialog_text = "Se acabó el tiempo para completar el nivel 3.\nDebes reiniciar el nivel."
	dialog.connect("confirmed", Callable(self, "_on_timeout_confirmed"))
	add_child(dialog)
	dialog.popup_centered()
	print("⏰ Tiempo agotado - Mostrando mensaje")

## Callback cuando se confirma el mensaje de timeout
func _on_timeout_confirmed() -> void:
	print("🔄 Reiniciando Nivel 3...")
	get_tree().reload_current_scene()


## Para debug - presiona D para ver el mapa del grid
func _input(event: InputEvent) -> void:
	# Debug: presiona D para ver el mapa
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_D:
			if grid:
				grid.debug_print_all_entities()
	
	# Si el modo borrar está activo, manejar clics para borrar cintas
	if delete_mode:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				try_delete_conveyor_at_position(event.global_position)
		elif event is InputEventScreenTouch:
			if event.pressed and not event.double_tap:  # Touch simple (no doble tap)
				var camera_obj = get_viewport().get_camera_2d()
				if camera_obj:
					var viewport_size = get_viewport().get_visible_rect().size
					var offset = (event.position - viewport_size / 2) / camera_obj.zoom
					var world_pos = camera_obj.get_screen_center_position() + offset
					try_delete_conveyor_at_position(world_pos)
		return  # No procesar otros eventos en modo borrar
	
	# Rotar cintas con clic derecho (mouse) o toque largo (móvil)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			try_rotate_conveyor_at_position(event.global_position)
	
	# En móvil, usaremos doble tap para rotar
	elif event is InputEventScreenTouch:
		if event.pressed and event.double_tap:
			var camera_obj = get_viewport().get_camera_2d()
			if camera_obj:
				var viewport_size = get_viewport().get_visible_rect().size
				var offset = (event.position - viewport_size / 2) / camera_obj.zoom
				var world_pos = camera_obj.get_screen_center_position() + offset
				try_rotate_conveyor_at_position(world_pos)


## Intenta rotar una cinta en la posición dada
func try_rotate_conveyor_at_position(world_pos: Vector2) -> void:
	if not grid:
		return
	
	var cell = grid.world_to_grid(world_pos)
	var entity = grid.get_entity_at(cell)
	
	if entity and entity is ConveyorBelt:
		entity.rotate_direction()
		print("🔄 Rotando cinta en celda: ", cell)


## Intenta borrar una cinta o máquina en la posición dada
func try_delete_conveyor_at_position(world_pos: Vector2) -> void:
	if not grid:
		return
	
	var cell = grid.world_to_grid(world_pos)
	var entity = grid.get_entity_at(cell)
	
	# Borrar cintas o máquinas (fusión normal, super-fusión y ultimate-fusión)
	if entity and (entity is ConveyorBelt or entity is FusionMachine or entity is SuperFusionMachine or entity is UltimateFusionMachine):
		var entity_type = "entidad"
		var economy_type = ""
		
		if entity is ConveyorBelt:
			entity_type = "cinta"
			economy_type = "conveyor"
		elif entity is UltimateFusionMachine:
			entity_type = "ultimate-máquina"
			economy_type = "ultimate_fusion_machine"
		elif entity is SuperFusionMachine:
			entity_type = "super-máquina"
			economy_type = "super_fusion_machine"
		elif entity is FusionMachine:
			entity_type = "máquina"
			economy_type = "fusion_machine"
		
		print("🗑️ Borrando ", entity_type, " en celda: ", cell)
		
		# Dar reembolso
		if EconomyManager and economy_type != "":
			EconomyManager.refund(economy_type)
		
		# Si es una cinta con item, destruirlo
		if entity is ConveyorBelt and entity.current_item:
			entity.current_item.queue_free()
		
		# Si es una máquina con inputs, destruirlos
		if (entity is FusionMachine or entity is SuperFusionMachine or entity is UltimateFusionMachine):
			if entity.input_a:
				entity.input_a.queue_free()
			if entity.input_b:
				entity.input_b.queue_free()
		
		# Remover del grid
		grid.remove_entity(cell)
		
		# Destruir la entidad
		entity.queue_free()
		
		print("✅ ", entity_type.capitalize(), " eliminada exitosamente")
	else:
		if entity:
			print("⚠️ No se puede borrar: ", entity.get_class())
		else:
			print("⚠️ No hay nada en esa celda")


## Callback cuando cambia el modo borrar
func _on_delete_mode_changed(is_active: bool) -> void:
	delete_mode = is_active
	print("🔄 Modo borrar cambiado a: ", "ACTIVO" if is_active else "INACTIVO")


## Configura la cámara para móvil
func setup_camera() -> void:
	if camera:
		camera.position = Vector2(571, 384)  # Centro del viewport 1142x648
		camera.zoom = Vector2(1, 0.9)


## Centra el grid en la pantalla
func center_grid() -> void:
	if grid:
		# Obtener tamaño del viewport
		var viewport_size = get_viewport_rect().size
		
		# Calcular el tamaño total del grid en píxeles
		var grid_width_px = grid.grid_width * grid.cell_size
		var grid_height_px = grid.grid_height * grid.cell_size
		
		# Calcular posición central considerando el menú superior (80px = 70px altura + 10px margen)
		var top_menu_height = 80
		var available_height = viewport_size.y - top_menu_height
		
		# Centrar horizontalmente y verticalmente (considerando el menú superior)
		var center_x = (viewport_size.x - grid_width_px) / 2.0
		var center_y = top_menu_height + (available_height - grid_height_px) / 2.0
		
		grid.position = Vector2(center_x, center_y)
		
		# Actualizar posición de la cámara al centro del grid
		if camera:
			var grid_center_x = center_x + (grid_width_px / 2.0)
			var grid_center_y = center_y + (grid_height_px / 2.0)
			camera.position = Vector2(grid_center_x, grid_center_y)
		
		print("Grid y cámara centrados. Grid en: ", grid.position, " Cámara en: ", camera.position)


## Coloca los spawners de materiales en posiciones estratégicas
func setup_material_spawners() -> void:
	# Grid es 20x10, posiciones estratégicas para optimizar fusiones
	# Distribución: materiales espaciados para facilitar rutas de fusión
	
	var spawner_positions = {
		"Papel": Vector2i(2, 2),      # Esquina superior izquierda
		"Metal": Vector2i(17, 2),     # Esquina superior derecha
		"Vidrio": Vector2i(2, 7),     # Esquina inferior izquierda
		"Plastico": Vector2i(17, 7),  # Esquina inferior derecha
		"Madera": Vector2i(9, 4)      # Centro del grid
	}
	
	for material in spawner_positions.keys():
		var position = spawner_positions[material]
		spawn_material_at(position, material)
	
	print("✅ Spawners de materiales colocados estratégicamente en Level 3")


## Crea y coloca un spawner de material en una celda específica
func spawn_material_at(cell: Vector2i, material: String) -> void:
	var spawner_scene = preload("res://entities/materials/material_spawner.tscn")
	var spawner = spawner_scene.instantiate()
	spawner.material_type = material
	spawner.spawn_interval = randf_range(3.0, 5.0)  # Intervalo un poco más largo para nivel 3
	
	grid.add_child(spawner)
	grid.place_entity(spawner, cell)


## Agrega el botón de Super-Máquina al menú superior
func add_super_machine_button() -> void:
	if not top_menu:
		print("❌ No se encontró TopMenu")
		return
	
	var hbox = top_menu.get_node("Panel/HBoxContainer")
	if not hbox:
		print("❌ No se encontró HBoxContainer")
		return
	
	print("📦 Creando botón de Super-Máquina para Nivel 3...")
	
	# Crear contenedor
	var super_machine_container = MarginContainer.new()
	super_machine_container.name = "SuperMachineContainer"
	super_machine_container.add_theme_constant_override("margin_left", 10)
	super_machine_container.add_theme_constant_override("margin_right", 10)
	super_machine_container.add_theme_constant_override("margin_top", 10)
	super_machine_container.add_theme_constant_override("margin_bottom", 10)
	
	# Insertar después del botón de máquina normal
	var machine_container = hbox.get_node("MachineContainer")
	if machine_container:
		var machine_index = machine_container.get_index()
		hbox.add_child(super_machine_container)
		hbox.move_child(super_machine_container, machine_index + 1)
	else:
		hbox.add_child(super_machine_container)
	
	# Crear el botón draggable
	var super_machine_btn = preload("res://ui/top_menu/draggable_button.gd").new()
	super_machine_btn.name = "SuperMachineBtn"
	super_machine_btn.custom_minimum_size = Vector2(64, 64)
	super_machine_btn.texture_normal = load("res://assets/images/fusion_machine_level_two.png")
	super_machine_btn.ignore_texture_size = true
	super_machine_btn.stretch_mode = TextureButton.STRETCH_SCALE
	super_machine_btn.entity_scene = preload("res://entities/machines/super_fusion_machine.tscn")
	super_machine_btn.entity_name = "Super-Máquina"
	super_machine_container.add_child(super_machine_btn)
	
	# Conectar señal para desactivar modo borrar
	super_machine_btn.drag_started.connect(top_menu._on_any_drag_started)
	
	print("✅ Botón de Super-Máquina agregado exitosamente")


## Agrega el botón de Ultimate-Máquina al menú superior (nivel 3)
func add_ultimate_machine_button() -> void:
	if not top_menu:
		print("❌ No se encontró TopMenu")
		return
	
	var hbox = top_menu.get_node("Panel/HBoxContainer")
	if not hbox:
		print("❌ No se encontró HBoxContainer")
		return
	
	print("📦 Creando botón de Ultimate-Máquina para Nivel 3...")
	
	# Crear contenedor
	var ultimate_machine_container = MarginContainer.new()
	ultimate_machine_container.name = "UltimateMachineContainer"
	ultimate_machine_container.add_theme_constant_override("margin_left", 10)
	ultimate_machine_container.add_theme_constant_override("margin_right", 10)
	ultimate_machine_container.add_theme_constant_override("margin_top", 10)
	ultimate_machine_container.add_theme_constant_override("margin_bottom", 10)
	
	# Insertar después del botón de super-máquina
	var super_machine_container = hbox.get_node("SuperMachineContainer")
	if super_machine_container:
		var super_machine_index = super_machine_container.get_index()
		hbox.add_child(ultimate_machine_container)
		hbox.move_child(ultimate_machine_container, super_machine_index + 1)
	else:
		hbox.add_child(ultimate_machine_container)
	
	# Crear el botón draggable
	var ultimate_machine_btn = preload("res://ui/top_menu/draggable_button.gd").new()
	ultimate_machine_btn.name = "UltimateMachineBtn"
	ultimate_machine_btn.custom_minimum_size = Vector2(64, 64)
	ultimate_machine_btn.texture_normal = load("res://assets/images/fusion_machine_level_three.png")
	ultimate_machine_btn.ignore_texture_size = true
	ultimate_machine_btn.stretch_mode = TextureButton.STRETCH_SCALE
	ultimate_machine_btn.entity_scene = preload("res://entities/machines/ultimate_fusion_machine.tscn")
	ultimate_machine_btn.entity_name = "Ultimate-Máquina"
	ultimate_machine_container.add_child(ultimate_machine_btn)
	
	# Conectar señal para desactivar modo borrar
	ultimate_machine_btn.drag_started.connect(top_menu._on_any_drag_started)
	
	print("✅ Botón de Ultimate-Máquina agregado exitosamente")


## Agrega el display de monedas a la UI
func add_money_display() -> void:
	var money_display_scene = preload("res://ui/money_display/money_display.tscn")
	money_display = money_display_scene.instantiate()
	add_child(money_display)
	print("💰 Display de monedas agregado")
	
	
##NUEVO
func setup_objective_hub_ui() -> void:
	hub_objective = hub_objective_scene.instantiate()
	add_child(hub_objective)

	# poblar primero
	hub_objective.objectives.clear()
	for obj in ObjectiveManager.get_all_for_ui():
		hub_objective.add_objective_with_icon(obj.title, obj.target, obj.icon_tex, obj.current)

	hub_objective.num_slots = ObjectiveManager.objectives.size()
	hub_objective.setup_background()
	hub_objective.setup_container()
	hub_objective.refresh_from(ObjectiveManager.objectives)

	# conectar señales
	if not ObjectiveManager.objective_updated.is_connected(hub_objective.on_objective_progress):
		ObjectiveManager.objective_updated.connect(hub_objective.on_objective_progress)
	if not ObjectiveManager.objective_completed.is_connected(hub_objective.on_objective_complete):
		ObjectiveManager.objective_completed.connect(hub_objective.on_objective_complete)
	if not ObjectiveManager.all_objectives_completed.is_connected(hub_objective.on_all_complete):
		ObjectiveManager.all_objectives_completed.connect(hub_objective.on_all_complete)

	_position_hub()

func _position_hub() -> void:
	var grid_width_px = grid.grid_width * grid.cell_size
	var hub_size = hub_objective.get_size()         # ya actualizado
	var hub_x = grid.position.x + (grid_width_px - hub_size.x) * 0.5
	var hub_y = grid.position.y + grid.grid_height * grid.cell_size + 16
	hub_objective.position = Vector2(hub_x, hub_y)

func _on_vp_resized() -> void:
	center_grid()
	if is_instance_valid(hub_objective):
		_position_hub()


##Leo aqui puedes implementar la llamada a tu modallll para el nivel 3
## Callback cuando el jugador pierde por falta de dinero
func _on_game_over_no_money() -> void:
	
	print("💀 ¡PERDISTE EL JUEGO EN NIVEL 3! 💀")
	
	
