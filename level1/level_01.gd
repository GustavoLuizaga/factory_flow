extends Node2D

## Level 1 - Tablero principal con spawners de materiales

@onready var grid: Grid = $Grid
@onready var top_menu: CanvasLayer = $TopMenu
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	print("=== Level 1 iniciado ===")
	setup_camera()
	setup_material_spawners()


## Configura la cámara para móvil
func setup_camera() -> void:
	if camera:
		camera.position = Vector2(571, 324)  # Centro del viewport 1142x648
		camera.zoom = Vector2(1.0, 1.0)


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
