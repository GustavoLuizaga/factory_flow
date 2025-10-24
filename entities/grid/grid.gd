extends Node2D
class_name Grid

## Sistema de grilla/tablero donde se colocan entidades
## Gestiona el snap, colisiones y posicionamiento

@export var cell_size: int = 64
@export var grid_width: int = 10
@export var grid_height: int = 12

var occupied_cells: Dictionary = {}  # Vector2i -> Entity
var entities: Array = []

@onready var background: ColorRect = $Background


func _ready() -> void:
	GameManager.current_grid = self
	setup_background()
	draw_grid_lines()


## Configura el fondo del grid
func setup_background() -> void:
	if background:
		background.size = Vector2(grid_width * cell_size, grid_height * cell_size)
		background.color = Color(0.2, 0.2, 0.25, 1.0)


## Dibuja las líneas del grid para visualización
func draw_grid_lines() -> void:
	queue_redraw()


func _draw() -> void:
	# Dibujar líneas horizontales y verticales
	for x in range(grid_width + 1):
		draw_line(
			Vector2(x * cell_size, 0),
			Vector2(x * cell_size, grid_height * cell_size),
			Color(0.3, 0.3, 0.35, 0.5),
			1.0
		)
	
	for y in range(grid_height + 1):
		draw_line(
			Vector2(0, y * cell_size),
			Vector2(grid_width * cell_size, y * cell_size),
			Color(0.3, 0.3, 0.35, 0.5),
			1.0
		)


## Convierte una posición del mundo a coordenadas de celda
func world_to_grid(world_pos: Vector2) -> Vector2i:
	# Convertir la posición global del mundo a posición local del grid
	var local_pos = to_local(world_pos)
	
	# Calcular la celda
	var cell = Vector2i(
		int(floor(local_pos.x / cell_size)),
		int(floor(local_pos.y / cell_size))
	)
	
	return cell


## Convierte coordenadas de celda a posición del mundo (centro de la celda)
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return global_position + Vector2(
		grid_pos.x * cell_size + cell_size / 2,
		grid_pos.y * cell_size + cell_size / 2
	)


## Verifica si una celda está dentro de los límites del grid
func is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < grid_width and cell.y >= 0 and cell.y < grid_height


## Verifica si una celda está ocupada
func is_cell_occupied(cell: Vector2i) -> bool:
	return occupied_cells.has(cell)


## Obtiene la entidad en una celda específica
func get_entity_at(cell: Vector2i) -> Node:
	return occupied_cells.get(cell, null)


## Coloca una entidad en el grid
func place_entity(entity: Node2D, cell: Vector2i) -> bool:
	if not is_valid_cell(cell):
		print("Celda fuera de límites: ", cell)
		return false
	
	if is_cell_occupied(cell):
		print("Celda ocupada: ", cell)
		return false
	
	# Colocar entidad
	occupied_cells[cell] = entity
	entities.append(entity)
	
	# Posicionar en el mundo
	entity.global_position = grid_to_world(cell)
	
	# Notificar a la entidad
	if entity.has_method("on_placed_in_grid"):
		entity.on_placed_in_grid(cell)
	
	print("Entidad colocada en: ", cell)
	return true


## Remueve una entidad del grid
func remove_entity(cell: Vector2i) -> void:
	if occupied_cells.has(cell):
		var entity = occupied_cells[cell]
		occupied_cells.erase(cell)
		entities.erase(entity)


## Obtiene la celda adyacente en una dirección
func get_adjacent_cell(cell: Vector2i, direction: Vector2) -> Vector2i:
	return cell + Vector2i(int(direction.x), int(direction.y))
