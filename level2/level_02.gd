extends Node2D

## Level 2 - Versión de prueba (solo Grid y Menú)

@onready var grid: Grid = $Grid
@onready var top_menu: CanvasLayer = $TopMenu
@onready var camera: Camera2D = $Camera2D

var delete_mode: bool = false

func _ready() -> void:
	print("=== Level 2 iniciado (Versión de prueba) ===")
	setup_camera()
	center_grid()
	setup_material_spawners()  # Agregar spawners estratégicos
	
	# Conectar la señal del modo borrar
	if top_menu:
		top_menu.delete_mode_changed.connect(_on_delete_mode_changed)


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
	
	print("✅ Spawners de materiales colocados estratégicamente en Level 2")


## Crea y coloca un spawner de material en una celda específica
func spawn_material_at(cell: Vector2i, material: String) -> void:
	var spawner_scene = preload("res://entities/materials/material_spawner.tscn")
	var spawner = spawner_scene.instantiate()
	spawner.material_type = material
	spawner.spawn_interval = randf_range(3.0, 5.0)  # Intervalo un poco más largo para nivel 2
	
	grid.add_child(spawner)
	grid.place_entity(spawner, cell)
