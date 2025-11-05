extends Node2D
class_name ConveyorBelt

## Cinta transportadora que mueve items en una dirección
## Puede tener 4 direcciones: UP, DOWN, LEFT, RIGHT

enum Direction { UP, DOWN, LEFT, RIGHT }

@export var direction: Direction = Direction.RIGHT
@export var transfer_time: float = 1.0  # Tiempo para mover item a siguiente celda

var current_item: Item = null
var current_cell: Vector2i = Vector2i.ZERO
var direction_vector: Vector2 = Vector2.RIGHT
var transfer_timer: float = 0.0
var conveyor_textures = {
	Direction.UP: preload("res://assets/images/conveyor_belt_up.png"),
	Direction.DOWN: preload("res://assets/images/conveyor_belt_down.png"),
	Direction.LEFT: preload("res://assets/images/conveyor_belt_left.png"),
	Direction.RIGHT: preload("res://assets/images/conveyor_belt_right.png")
}

@onready var arrow: Label = $Arrow
@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	update_direction()
	update_visual()
	adjust_sprite_size()


func _process(delta: float) -> void:
	if current_item:
		transfer_timer += delta
		if transfer_timer >= transfer_time:
			transfer_item_to_next()
			transfer_timer = 0.0


## Callback cuando se coloca en el grid
func on_placed_in_grid(cell: Vector2i) -> void:
	current_cell = cell
	print("Conveyor colocado en: ", cell, " dirección: ", get_direction_name())


## Rota la dirección de la cinta 90 grados (sentido horario)
func rotate_direction() -> void:
	match direction:
		Direction.UP:
			direction = Direction.RIGHT
		Direction.RIGHT:
			direction = Direction.DOWN
		Direction.DOWN:
			direction = Direction.LEFT
		Direction.LEFT:
			direction = Direction.UP
	
	update_direction()
	update_visual()
	print("🔄 Cinta en [", current_cell, "] rotada a: ", get_direction_name())


## Actualiza el vector de dirección según el enum
func update_direction() -> void:
	match direction:
		Direction.UP:
			direction_vector = Vector2.UP
		Direction.DOWN:
			direction_vector = Vector2.DOWN
		Direction.LEFT:
			direction_vector = Vector2.LEFT
		Direction.RIGHT:
			direction_vector = Vector2.RIGHT


## Actualiza el visual según la dirección
func update_visual() -> void:
	# Actualizar el sprite con la textura correspondiente
	if sprite:
		sprite.texture = conveyor_textures[direction]
		adjust_sprite_size()
	
	# Ocultar la flecha, ahora usamos sprites
	if arrow:
		arrow.visible = false


## Obtiene el nombre de la dirección
func get_direction_name() -> String:
	match direction:
		Direction.UP: return "UP"
		Direction.DOWN: return "DOWN"
		Direction.LEFT: return "LEFT"
		Direction.RIGHT: return "RIGHT"
	return "UNKNOWN"


## Acepta un item desde otra entidad
func accept_item(item: Item) -> bool:
	if current_item != null:
		print("   ⏸️ Conveyor [", current_cell, "] ocupada, rechazando item")
		return false  # Ya hay un item aquí
	
	current_item = item
	transfer_timer = 0.0
	
	# Actualizar la celda del item para que coincida con la de esta cinta
	item.current_cell = current_cell
	
	# Mover el item a la posición de esta cinta
	if GameManager.current_grid:
		item.move_to_position(global_position)
	
	print("   ✅ Conveyor [", current_cell, "] dir:", get_direction_name(), " aceptó item:", item.item_type)
	return true


## Transfiere el item a la siguiente celda
func transfer_item_to_next() -> void:
	if not current_item:
		return
	
	var grid = GameManager.current_grid
	if not grid:
		return
	
	# Calcular la siguiente celda basada en la dirección
	var next_cell = grid.get_adjacent_cell(current_cell, direction_vector)
	
	print("🔄 Conveyor [", current_cell, "] dir:", get_direction_name(), " vector:", direction_vector, " → next:", next_cell)
	
	# Verificar si la celda existe
	if not grid.is_valid_cell(next_cell):
		print("   ⚠️ Celda fuera de límites - destruyendo item")
		current_item.destroy()
		current_item = null
		return
	
	var next_entity = grid.get_entity_at(next_cell)
	
	if next_entity != null:
		var entity_type = "?"
		if next_entity is ConveyorBelt:
			entity_type = "Conveyor(" + next_entity.get_direction_name() + ")"
		elif next_entity is MaterialSpawner:
			entity_type = "Spawner"
		else:
			entity_type = next_entity.get_class()
		
		print("   ✓ Entidad en [", next_cell, "]: ", entity_type)
	else:
		print("   ✗ NO hay entidad en [", next_cell, "]")
	
	# Si hay una entidad, intentar pasarle el item
	if next_entity != null:
		# Intentar pasar el item a la siguiente entidad
		if next_entity.has_method("accept_item"):
			if next_entity.accept_item(current_item):
				current_item = null
				transfer_timer = 0.0
				print("   ✅ Item transferido exitosamente")
			else:
				print("   ⏸️ Entidad ocupada - esperando...")
		else:
			print("   ❌ Entidad no puede recibir items - destruyendo")
			current_item.destroy()
			current_item = null
	else:
		# No hay entidad en la siguiente celda - el item cae/desaparece
		print("   💨 Item destruido (no hay receptor)")
		current_item.destroy()
		current_item = null


## Puede recibir items de spawners o cintas anteriores
func can_receive_item() -> bool:
	return current_item == null


## Ajusta el tamaño del sprite para que encaje en una celda del grid
func adjust_sprite_size() -> void:
	if sprite and sprite.texture:
		# Obtenemos el tamaño deseado (64x64 que es el tamaño de la celda del grid)
		var target_size = Vector2(64, 64)
		
		# Calculamos la escala necesaria
		var scale_x = target_size.x / sprite.texture.get_width()
		var scale_y = target_size.y / sprite.texture.get_height()
		
		# Aplicamos la escala al sprite
		sprite.scale = Vector2(scale_x, scale_y)
