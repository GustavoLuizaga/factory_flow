extends Node2D

## Level 1 - Tablero principal con spawners de materiales

@onready var grid: Grid = $Grid
@onready var top_menu: CanvasLayer = $TopMenu
@onready var camera: Camera2D = $Camera2D


var hub_objective_scene: PackedScene = preload("res://ui//barra_objetivos/hub_objetive.tscn")
var hub_objective: Node2D

@export_enum("fixed","random") var spawners_mode := "fixed"  # elige sin tocar código ajeno

func _ready() -> void:
	print("=== Level 1 iniciado ===")
	randomize()
	setup_camera()
	setup_material_spawners()
	ObjectiveManager.reset_for_level(1)  # <<< NUEVO: limpia y carga objetivos desde BD
	setup_objective_hub_ui() # <<< NUEVO


## Configura la cámara para móvil
func setup_camera() -> void:
	if camera:
		#camera.position = Vector2(571, 324)  # Centro del viewport 1142x648
		camera.position = Vector2(571, 424)
		camera.zoom = Vector2(0.8, 0.8)

## Coloca los spawners de materiales en el grid
func setup_material_spawners() -> void:
	if spawners_mode == "fixed":
		_setup_spawners_fixed()
	else:
		_setup_spawners_random()
	print("Spawners de materiales colocados")
	
# Tu versión: fila superior
func _setup_spawners_fixed() -> void:
	spawn_material_at(Vector2i(1, 0), "Papel")
	spawn_material_at(Vector2i(3, 0), "Metal")
	spawn_material_at(Vector2i(5, 0), "Plástico")
	spawn_material_at(Vector2i(7, 0), "Madera")
	spawn_material_at(Vector2i(9, 0), "Vidrio")

# Versión de tu compañero: aleatoria
func _setup_spawners_random() -> void:
	var used_positions: Array[Vector2i] = []
	var materials = ["Papel", "Metal", "Plastico", "Madera", "Vidrio"]

	for material in materials:
		var random_x = randi() % grid.grid_width
		var random_y = randi() % grid.grid_height
		var position = Vector2i(random_x, random_y)

		while position in used_positions:
			random_x = randi() % grid.grid_width
			random_y = randi() % grid.grid_height
			position = Vector2i(random_x, random_y)

		used_positions.append(position)
		spawn_material_at(position, material)


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

	# Posición bajo el grid
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

	print("Hub de objetivos inicializado desde base de datos")
