extends Node2D
class_name FusionMachine

## Máquina que recibe 2 materiales y los fusiona según recetas
## Tiene 2 entradas (input_a, input_b) y 1 salida

@export var fusion_time: float = 2.0  # Tiempo de procesamiento

var input_a: Item = null
var input_b: Item = null
var is_processing: bool = false
var process_timer: float = 0.0
var current_cell: Vector2i = Vector2i.ZERO

@onready var sprite: Sprite2D = $Sprite
@onready var status_label: Label = $StatusLabel
@onready var input_a_marker: ColorRect = $InputAMarker
@onready var input_b_marker: ColorRect = $InputBMarker


func _ready() -> void:
	update_visual()
	update_status()


func _process(delta: float) -> void:
	if is_processing:
		process_timer += delta
		update_status()
		
		if process_timer >= fusion_time:
			complete_fusion()
			process_timer = 0.0
			is_processing = false
	
	# Intentar fusionar si tenemos ambos inputs
	if input_a and input_b and not is_processing:
		try_fuse()


## Callback cuando se coloca en el grid
func on_placed_in_grid(cell: Vector2i) -> void:
	current_cell = cell
	print("Máquina colocada en: ", cell)


## Actualiza el visual de la máquina
func update_visual() -> void:
	# El sprite ya no necesita cambios de color
	# Solo actualizamos los marcadores de input
	if input_a_marker:
		input_a_marker.color = Color(1, 0, 0, 0.5) if input_a == null else Color(0, 1, 0, 0.8)
	
	if input_b_marker:
		input_b_marker.color = Color(1, 0, 0, 0.5) if input_b == null else Color(0, 1, 0, 0.8)


## Actualiza el label de estado
func update_status() -> void:
	if status_label:
		if is_processing:
			var progress = int((process_timer / fusion_time) * 100)
			status_label.text = str(progress) + "%"
		else:
			var count = 0
			if input_a: count += 1
			if input_b: count += 1
			status_label.text = str(count) + "/2"
	
	update_visual()


## Acepta un item en uno de los slots de entrada
func accept_item(item: Item) -> bool:
	# Solo aceptar materiales base, no productos
	if not GameManager.is_base_material(item.item_type):
		print("⚠️ Máquina rechaza producto: ", item.item_type, " (solo acepta materiales base)")
		return false
	
	# Intentar colocar en input_a primero
	if input_a == null:
		input_a = item
		item.move_to_position(global_position + Vector2(-15, 0))
		print("Máquina recibió item A: ", item.item_type)
		update_status()
		return true
	
	# Si input_a está ocupado, intentar input_b
	if input_b == null:
		input_b = item
		item.move_to_position(global_position + Vector2(15, 0))
		print("Máquina recibió item B: ", item.item_type)
		update_status()
		return true
	
	# Ambos slots llenos
	return false


## Intenta fusionar los dos materiales
func try_fuse() -> void:
	if not input_a or not input_b:
		return
	
	var result = GameManager.check_recipe(input_a.item_type, input_b.item_type)
	
	if result != "":
		print("¡Receta válida! ", input_a.item_type, " + ", input_b.item_type, " = ", result)
		is_processing = true
		process_timer = 0.0
	else:
		print("Receta inválida: ", input_a.item_type, " + ", input_b.item_type)
		# Destruir items inválidos o expulsarlos
		input_a.destroy()
		input_b.destroy()
		input_a = null
		input_b = null
		update_status()


## Completa la fusión y genera el producto
func complete_fusion() -> void:
	if not input_a or not input_b:
		return
	
	var result = GameManager.check_recipe(input_a.item_type, input_b.item_type)
	
	if result == "":
		return
	
	print("¡Fusión completada! Producto: ", result)
	
	# Destruir inputs
	input_a.destroy()
	input_b.destroy()
	input_a = null
	input_b = null
	
	# Crear item de salida
	produce_output(result)
	
	# Registrar fusión
	GameManager.register_fusion()
	update_status()


## Produce el item de salida
func produce_output(product_type: String) -> void:
	var grid = GameManager.current_grid
	if not grid:
		return
	
	# Intentar colocar el producto en celdas adyacentes (prioridad: abajo, derecha, izquierda, arriba)
	var directions = [Vector2.DOWN, Vector2.RIGHT, Vector2.LEFT, Vector2.UP]
	
	for direction in directions:
		var output_cell = grid.get_adjacent_cell(current_cell, direction)
		
		if not grid.is_valid_cell(output_cell):
			continue  # Probar siguiente dirección
		
		var next_entity = grid.get_entity_at(output_cell)
		
		# Caso 1: Hay una entidad que puede recibir items (cinta transportadora)
		if next_entity and next_entity.has_method("accept_item"):
			var item_scene = preload("res://entities/items/item.tscn")
			var new_item = item_scene.instantiate()
			grid.add_child(new_item)
			new_item.setup(product_type, output_cell)
			
			# Posicionar en la máquina antes de enviarlo
			new_item.global_position = global_position
			
			if next_entity.accept_item(new_item):
				print("Producto '", product_type, "' enviado a celda: ", output_cell)
				return  # Éxito, salir
			else:
				new_item.queue_free()  # La entidad está ocupada, probar siguiente dirección
		
		# Caso 2: La celda está vacía y no ocupada
		elif next_entity == null and not grid.is_cell_occupied(output_cell):
			var item_scene = preload("res://entities/items/item.tscn")
			var new_item = item_scene.instantiate()
			grid.add_child(new_item)
			new_item.setup(product_type, output_cell)
			
			# Posicionar correctamente: como es hijo del grid, usar posición local
			var local_pos = Vector2(
				output_cell.x * grid.cell_size + grid.cell_size / 2,
				output_cell.y * grid.cell_size + grid.cell_size / 2
			)
			new_item.position = local_pos
			
			print("Producto '", product_type, "' depositado en celda vacía: ", output_cell, " pos: ", local_pos)
			return  # Éxito, salir
	
	# Si llegamos aquí, todas las celdas adyacentes están bloqueadas
	print("⚠️ Máquina bloqueada: no hay espacio para el output")
