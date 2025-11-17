extends Node2D
class_name UltimateFusionMachine

## Máquina de Ultimate Fusion (Nivel 3)
## Recibe 2 SUPER-FUSIONES y los combina en fusiones definitivas
## Solo acepta super-fusiones (elementos 16-24), NO materiales base ni fusiones nivel 1

@export var fusion_time: float = 3.0  # Tiempo de procesamiento (más lento que las otras)

var input_a: Item = null
var input_b: Item = null
var is_processing: bool = false
var process_timer: float = 0.0
var current_cell: Vector2i = Vector2i.ZERO

# Productos ya generados en esta máquina específica
var completed_products: Array[String] = []

# IDs de elementos que esta máquina acepta (super-fusiones nivel 2)
const ACCEPTED_ELEMENTS: Array[int] = [12, 16, 17, 18, 19, 20, 21, 22, 23, 24]

# Combinaciones válidas para Ultimate Fusion
const VALID_COMBINATIONS: Array[Dictionary] = [
	{"elemento1": 16, "elemento2": 17, "resultado": 25},
	{"elemento1": 18, "elemento2": 19, "resultado": 26},
	{"elemento1": 20, "elemento2": 21, "resultado": 27},
	{"elemento1": 22, "elemento2": 23, "resultado": 28},
	{"elemento1": 12, "elemento2": 24, "resultado": 29}
]

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
	print("Ultimate-Máquina colocada en: ", cell)


## Actualiza el visual de la máquina
func update_visual() -> void:
	# Cargar el sprite de nivel 3
	if sprite:
		sprite.texture = load("res://assets/images/fusion_machine_level_three.png")
	
	# Actualizar los marcadores de input
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


## Verifica si un elemento es aceptado por esta máquina
func is_accepted_element(item_type: String) -> bool:
	var element_id = GameManager.get_element_id_by_name(item_type)
	return element_id in ACCEPTED_ELEMENTS


## Acepta un item en uno de los slots de entrada
func accept_item(item: Item) -> bool:
	# IMPORTANTE: Solo aceptar super-fusiones específicas
	if not is_accepted_element(item.item_type):
		print("⚠️ Ultimate-Máquina rechaza y DESTRUYE elemento: ", item.item_type, " (solo acepta super-fusiones específicas)")
		# Destruir el elemento no válido para no bloquear el flujo
		item.destroy()
		return true  # Retornar true para que la cinta libere su referencia
	
	# Intentar colocar en input_a primero
	if input_a == null:
		input_a = item
		item.move_to_position(global_position + Vector2(-15, 0))
		print("Ultimate-Máquina recibió super-fusión A: ", item.item_type)
		update_status()
		return true
	
	# Si input_a está ocupado, intentar input_b
	if input_b == null:
		input_b = item
		item.move_to_position(global_position + Vector2(15, 0))
		print("Ultimate-Máquina recibió super-fusión B: ", item.item_type)
		update_status()
		return true
	
	# Ambos slots llenos - rechazar
	print("⏸️ Ultimate-Máquina llena, rechazando item")
	return false


## Verifica si una combinación es válida para Ultimate Fusion
func check_ultimate_recipe(item_a_type: String, item_b_type: String) -> String:
	var id_a = GameManager.get_element_id_by_name(item_a_type)
	var id_b = GameManager.get_element_id_by_name(item_b_type)
	
	for combo in VALID_COMBINATIONS:
		# Verificar ambas direcciones de la combinación
		if (combo["elemento1"] == id_a and combo["elemento2"] == id_b) or \
		   (combo["elemento1"] == id_b and combo["elemento2"] == id_a):
			var result_id = combo["resultado"]
			return GameManager.get_element_name_by_id(result_id)
	
	return ""


## Intenta fusionar los dos productos
func try_fuse() -> void:
	if not input_a or not input_b:
		return
	
	var result = check_ultimate_recipe(input_a.item_type, input_b.item_type)
	
	# Verificar si este producto ya fue creado en ESTA máquina
	if result != "" and result in completed_products:
		print("⚠️ Esta ultimate-máquina ya produjo: ", result, " - Rechazando combinación")
		# Destruir items porque ya se produjo este producto aquí
		input_a.destroy()
		input_b.destroy()
		input_a = null
		input_b = null
		update_status()
		return
	
	if result != "":
		print("¡Ultimate-fusión válida! ", input_a.item_type, " + ", input_b.item_type, " = ", result)
		is_processing = true
		process_timer = 0.0
	else:
		print("Ultimate-fusión inválida: ", input_a.item_type, " + ", input_b.item_type)
		# Destruir items inválidos
		input_a.destroy()
		input_b.destroy()
		input_a = null
		input_b = null
		update_status()


## Completa la fusión y genera el producto
func complete_fusion() -> void:
	if not input_a or not input_b:
		return
	
	var result = check_ultimate_recipe(input_a.item_type, input_b.item_type)
	
	if result == "":
		return
	
	print("¡Ultimate-fusión completada! Producto: ", result)
	
	# Marcar este producto como completado en ESTA máquina
	if result not in completed_products:
		completed_products.append(result)
		print("✅ Ultimate-Máquina en ", current_cell, " completó: ", result)
	
	# Registrar la fusión en el GameManager para objetivos
	GameManager.register_completed_fusion(result)
	
	# Destruir inputs
	input_a.destroy()
	input_b.destroy()
	input_a = null
	input_b = null
	
	# Crear item de salida
	produce_output(result)
	
	# Actualizar objetivos
	ObjectiveManager.inc_by_element_name(result, 1)

	# Registrar fusión
	GameManager.register_fusion()
	update_status()


## Produce el item de salida
func produce_output(product_type: String) -> void:
	var grid = GameManager.current_grid
	if not grid:
		return
	
	# Intentar colocar el producto en celdas adyacentes
	# Prioridad: abajo, derecha, arriba, izquierda, luego diagonales
	var adjacent_offsets = [
		Vector2i(0, 1),   # Abajo
		Vector2i(1, 0),   # Derecha
		Vector2i(0, -1),  # Arriba
		Vector2i(-1, 0),  # Izquierda
		Vector2i(1, 1),   # Diagonal: abajo-derecha
		Vector2i(-1, 1),  # Diagonal: abajo-izquierda
		Vector2i(1, -1),  # Diagonal: arriba-derecha
		Vector2i(-1, -1)  # Diagonal: arriba-izquierda
	]
	
	for offset in adjacent_offsets:
		var output_cell = current_cell + offset
		
		# Verificar si la celda es válida
		if not grid.is_valid_cell(output_cell):
			continue  # Celda fuera del grid, probar siguiente
		
		# Verificar si hay una entidad en la celda
		var entity_at_cell = grid.get_entity_at(output_cell)
		if entity_at_cell != null:
			continue  # Hay una entidad (máquina, cinta, spawner), probar siguiente
		
		# Verificar si hay items en la celda
		var has_item = false
		for child in grid.get_children():
			if child is Item:
				if child.current_cell == output_cell:
					has_item = true
					break
		
		if has_item:
			continue  # Ya hay un item en esta celda, probar siguiente
		
		# ¡Celda libre! Colocar el producto aquí
		var item_scene = preload("res://entities/items/item.tscn")
		var new_item = item_scene.instantiate()
		grid.add_child(new_item)
		new_item.setup(product_type, output_cell)
		
		# IMPORTANTE: Hacer que el producto funcione como spawner
		new_item.is_static_spawner = true
		new_item.spawn_interval = 3.0
		
		# Posicionar correctamente: como es hijo del grid, usar posición local
		var local_pos = Vector2(
			output_cell.x * grid.cell_size + grid.cell_size / 2,
			output_cell.y * grid.cell_size + grid.cell_size / 2
		)
		new_item.position = local_pos
		
		print("✅ Ultimate-Producto '", product_type, "' depositado en celda: ", output_cell, " (funciona como spawner)")
		return  # Éxito, salir
	
	# Si llegamos aquí, todas las celdas adyacentes están bloqueadas
	print("❌ ULTIMATE-MÁQUINA BLOQUEADA: No hay espacio libre en las 8 celdas adyacentes para generar el producto '", product_type, "'")
