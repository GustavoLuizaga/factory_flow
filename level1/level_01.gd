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
	# Crear spawners en la fila superior del grid
	spawn_material_at(Vector2i(1, 0), "Papel")
	spawn_material_at(Vector2i(3, 0), "Metal")
	spawn_material_at(Vector2i(5, 0), "Plastico")
	spawn_material_at(Vector2i(7, 0), "Madera")
	spawn_material_at(Vector2i(9, 0), "Vidrio")
	
	print("Spawners de materiales colocados")


## Crea y coloca un spawner de material en una celda específica
func spawn_material_at(cell: Vector2i, material: String) -> void:
	var spawner_scene = preload("res://entities/materials/material_spawner.tscn")
	var spawner = spawner_scene.instantiate()
	spawner.material_type = material
	spawner.spawn_interval = randf_range(2.5, 4.0)  # Spawn aleatorio
	
	grid.add_child(spawner)
	grid.place_entity(spawner, cell)
