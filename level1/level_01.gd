extends Node2D

## Level 1 - Tablero principal con spawners de materiales

@onready var grid: Grid = $Grid
@onready var top_menu: CanvasLayer = $TopMenu
@onready var camera: Camera2D = $Camera2D
@export var modal_scene: PackedScene = preload("res://level_modal/level_complete_modal.tscn")
var hub_objective_scene: PackedScene = preload("res://ui//barra_objetivos/hub_objetive.tscn")
var hub_objective: Node2D
var delete_mode: bool = false

func _ready() -> void:
	print("=== Level 1 iniciado ===")
	setup_camera()
	center_grid()  # <<< NUEVO: Centrar el grid
	setup_material_spawners()
	ObjectiveManager.reset_for_level(1)  # <<< NUEVO: limpia y carga objetivos desde BD
	setup_objective_hub_ui() # <<< NUEVO
	
	# Conectar la señal del modo borrar
	if top_menu:
		top_menu.delete_mode_changed.connect(_on_delete_mode_changed)
	
	#Desbloquear nivel 2
	if not ObjectiveManager.all_objectives_completed.is_connected(_on_all_done):
		ObjectiveManager.all_objectives_completed.connect(_on_all_done)

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


## Intenta borrar una cinta en la posición dada
func try_delete_conveyor_at_position(world_pos: Vector2) -> void:
	if not grid:
		return
	
	var cell = grid.world_to_grid(world_pos)
	var entity = grid.get_entity_at(cell)
	
	# Solo borrar si es una cinta transportadora
	if entity and entity is ConveyorBelt:
		print("🗑️ Borrando cinta en celda: ", cell)
		
		# Si la cinta tiene un item, destruirlo también
		if entity.current_item:
			entity.current_item.queue_free()
		
		# Remover del grid
		grid.remove_entity(cell)
		
		# Destruir la entidad
		entity.queue_free()
		
		print("✅ Cinta eliminada exitosamente")
	else:
		if entity:
			print("⚠️ No se puede borrar: no es una cinta transportadora")
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


## Coloca los spawners de materiales en el grid
func setup_material_spawners() -> void:
	# Crear spawners en posiciones aleatorias
	var used_positions: Array[Vector2i] = []
	var materials = ["Papel", "Metal", "Plastico", "Madera", "Vidrio"]
	
	for material in materials:
		var random_x = randi() % grid.grid_width
		var random_y = randi() % grid.grid_height
		var position = Vector2i(random_x, random_y)
		
		# Evitar posiciones duplicadas
		while position in used_positions:
			random_x = randi() % grid.grid_width
			random_y = randi() % grid.grid_height
			position = Vector2i(random_x, random_y)
		
		used_positions.append(position)
		spawn_material_at(position, material)
	
	print("Spawners de materiales colocados")


## Crea y coloca un spawner de material en una celda específica
func spawn_material_at(cell: Vector2i, material: String) -> void:
	var spawner_scene = preload("res://entities/materials/material_spawner.tscn")
	var spawner = spawner_scene.instantiate()
	spawner.material_type = material
	spawner.spawn_interval = randf_range(2.5, 4.0)  # Spawn aleatorio
	
	grid.add_child(spawner)
	grid.place_entity(spawner, cell)


## --- NUEVO: crea e inserta la HUD de objetivos ---
func setup_objective_hub_ui() -> void:
	hub_objective = hub_objective_scene.instantiate()
	add_child(hub_objective)

	# Posición centrada bajo el grid
	var hub_y = grid.position.y + (grid.grid_height * grid.cell_size) + 16
	var grid_width_px = grid.grid_width * grid.cell_size
	var hub_w = hub_objective.get_size().x
	var hub_x = grid.position.x + (grid_width_px - hub_w) * 0.5
	hub_objective.position = Vector2(hub_x, hub_y)
	
	# --- limpia antes de añadir nuevos ---
	#hub_objective.populate_slots()
	hub_objective.objectives.clear() # vacía la lista
	
	# --- NUEVO: poblar objetivos desde la base de datos a través del autoload ---
	for obj in ObjectiveManager.get_all_for_ui():
		hub_objective.add_objective_with_icon(
			obj.title,
			obj.target,
			obj.icon_tex,
			obj.current
		)
		
	# ⬇️ Ajuste dinámico del HUD según la cantidad real
	hub_objective.num_slots = ObjectiveManager.objectives.size()
	hub_objective.setup_background()
	hub_objective.setup_container()
		
		# --- Conexión de señales ---
	if not ObjectiveManager.objective_updated.is_connected(hub_objective.on_objective_progress):
		ObjectiveManager.objective_updated.connect(hub_objective.on_objective_progress)

	if not ObjectiveManager.objective_completed.is_connected(hub_objective.on_objective_complete):
		ObjectiveManager.objective_completed.connect(hub_objective.on_objective_complete)

	if not ObjectiveManager.all_objectives_completed.is_connected(hub_objective.on_all_complete):
		ObjectiveManager.all_objectives_completed.connect(hub_objective.on_all_complete)

	hub_objective.refresh_from(ObjectiveManager.objectives)

	print("Hub de objetivos centrado bajo el grid")
	
##NUEVO unlock level
##NUEVO unlock level
func _on_all_done() -> void:
	print("🏆 ¡Todos los objetivos completados! Mostrando modal...")
	
	# Desbloquea el siguiente nivel (esto ya lo tenías)
	ProgressManager.unlock(2)
	
	# --- CÓDIGO DEL MODAL ---
	
	# 1. Crear una instancia (copia) de tu escena modal
	var modal = modal_scene.instantiate()
	
	# 2. Conectar las señales del modal a funciones de ESTE script (Level01)
	modal.menu_requested.connect(_on_go_to_menu)
	modal.next_level_requested.connect(_on_go_to_next_level)
	
	# 3. Añadir el modal a la escena actual
	add_child(modal)
	
	# 4. Mostrar el modal
	# (true = mostrar el botón "Siguiente Nivel")
	modal.show_modal(true)
	
	# --- AÑADE ESTAS DOS FUNCIONES AL FINAL ---

## Se llama cuando el jugador presiona "Volver al Menú" en el modal
func _on_go_to_menu():
	# (El modal ya quita la pausa, solo cambia de escena)
	# Asegúrate de que la ruta a tu menú sea correcta
	print("Cambiando a escena: Menú Principal")
	get_tree().change_scene_to_file("res://Menu/menu.tscn") 

## Se llama cuando el jugador presiona "Siguiente Nivel" en el modal
func _on_go_to_next_level():
	# (El modal ya quita la pausa)
	# Asegúrate de que la ruta a tu Nivel 2 sea correcta
	print("Cambiando a escena: Nivel 2")
	get_tree().change_scene_to_file("res://level2/level_02.tscn")
