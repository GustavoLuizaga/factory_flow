extends Node2D
class_name Item

## Item que representa un material o producto en el juego
## Puede moverse por cintas transportadoras y ser procesado por máquinas

@export var item_type: String = "Papel"
@export var move_speed: float = 100.0
@export var is_static_spawner: bool = false  # Si es true, funciona como spawner
@export var spawn_interval: float = 3.0

var current_cell: Vector2i = Vector2i.ZERO
var is_moving: bool = false
var target_position: Vector2 = Vector2.ZERO
var spawn_timer: float = 0.0

# Diccionario de sprites por tipo de material y producto
var sprite_paths: Dictionary = {
	# Materiales base
	"Papel": "res://assets/images/item_paper.png",
	"Metal": "res://assets/images/item_metal.png",
	"Plastico": "res://assets/images/item_plastic.png",
	"Madera": "res://assets/images/item_wood.png",
	"Vidrio": "res://assets/images/item_glass.png",
	# Productos fusionados (sin acentos para compatibilidad móvil)
	"Lata con etiqueta": "res://assets/images/Lata_con_etiqueta.png",
	"Botella con etiqueta": "res://assets/images/Botella_con_etiqueta.png",
	"Libro": "res://assets/images/Libro.png",
	"Caja de carton prensado": "res://assets/images/Caja_de_carton_prensado.png",
	"Botella con tapa metalica": "res://assets/images/Botella_con_tapa_metalica.png",
	"Botella con tapa plastica": "res://assets/images/Botella_con_tapa_plastica.png",
	"Cable recubierto": "res://assets/images/Cable_recubierto.png",
	"Herramienta con mango de madera": "res://assets/images/Herramienta_con_mango_de_madera.png",
	"Juguete": "res://assets/images/Juguete.png",
	"Ventana con marco de madera": "res://assets/images/Ventana_con_marco_de_madera.png",
	# Super fusiones (Nivel 2)
	"Pack de bebidas reciclado": "res://assets/images/subFusiones/Pack_de_bebidas_reciclado.png",
	"Biblioteca reciclada": "res://assets/images/subFusiones/Biblioteca_reciclada.png",
	"Coleccion de envases": "res://assets/images/subFusiones/Coleccion_de_envases.png",
	"Kit electrico reciclado": "res://assets/images/subFusiones/Kit_electrico_reciclado.png",
	"Botella de coleccion": "res://assets/images/subFusiones/Botella_de_coleccion.png",
	"Invernadero basico": "res://assets/images/subFusiones/Invernadero_basico.png",
	"E-book": "res://assets/images/subFusiones/E_book.png",
	"Botella con sorpresa": "res://assets/images/subFusiones/Botella_con_sorpresa.png",
	"Casa infantil de juguetes": "res://assets/images/subFusiones/Casa_infantil_de_juguetes.png",
	# Mesa de crafteo (si existe)
	"Mesa de crafteo": "res://assets/images/subFusiones/Mesa_de_crafteo.png",
	# Fusiones definitivas (Nivel 3)
	"Centro educativo de reciclaje": "res://assets/images/FucionesDefinitivas/Centro_educativo_de_reciclaje.png",
	"Estación educativa interactiva": "res://assets/images/FucionesDefinitivas/Estacion_educativa_interactiva.png",
	"Invernadero experimental": "res://assets/images/FucionesDefinitivas/Invernadero_experimental.png",
	"Taller de manualidades": "res://assets/images/FucionesDefinitivas/Taller_de_manualidades_infantil.png",
	"Taller de proyectos domésticos reciclados": "res://assets/images/FucionesDefinitivas/Taller_de_proyectos_domesticos_reciclados.png"
}

@onready var sprite: Sprite2D = $Sprite
@onready var label: Label = $Label


func _ready() -> void:
	update_visual()


func _process(delta: float) -> void:
	if is_static_spawner:
		# Comportamiento de spawner: enviar copias a cintas adyacentes
		spawn_timer += delta
		if spawn_timer >= spawn_interval:
			attempt_spawn()
			spawn_timer = 0.0
	elif is_moving:
		# Comportamiento normal: moverse
		var direction = (target_position - global_position).normalized()
		global_position += direction * move_speed * delta
		
		# Verificar si llegó al destino
		if global_position.distance_to(target_position) < 5.0:
			global_position = target_position
			is_moving = false


## Inicializa el item con un tipo específico
func setup(type: String, cell: Vector2i) -> void:
	item_type = type
	current_cell = cell
	update_visual()


## Actualiza el visual según el tipo de material
func update_visual() -> void:
	# Intentar buscar primero por nombre exacto, luego por nombre normalizado
	var texture_path: String = ""
	
	if sprite_paths.has(item_type):
		texture_path = sprite_paths[item_type]
	else:
		# Si no se encuentra, buscar normalizando (sin acentos)
		var normalized_type = _normalize_text(item_type)
		for key in sprite_paths.keys():
			if _normalize_text(key) == normalized_type:
				texture_path = sprite_paths[key]
				break
	
	if sprite and texture_path != "":
		# Cargar la textura
		var texture = load(texture_path) as Texture2D
		sprite.texture = texture
		
		# Auto-ajustar el tamaño a 50px (tamaño de celda)
		if texture:
			var texture_size = texture.get_size()
			var target_size = 50.0  # Tamaño de la celda
			
			# Calcular la escala necesaria para ajustar al tamaño de celda
			# Usar el lado más grande para calcular la escala
			var max_dimension = max(texture_size.x, texture_size.y)
			var scale_factor = target_size / max_dimension
			
			sprite.scale = Vector2(scale_factor, scale_factor)
		else:
			sprite.scale = Vector2(1, 1)  # Escala por defecto si no hay textura
	elif sprite:
		# Si no tiene sprite definido, usar color provisional
		sprite.texture = null
		var color_rect = ColorRect.new()
		color_rect.size = Vector2(40, 40)
		color_rect.position = Vector2(-20, -20)
		
		# Usar color específico del GameManager si está disponible
		var item_color = GameManager.get_material_color(item_type)
		color_rect.color = item_color
		
		add_child(color_rect)
		sprite.visible = false
	
	if label:
		label.text = item_type.substr(0, 3).to_upper()
		label.visible = false  # Ocultar etiqueta si hay sprite


## Normaliza texto quitando acentos
static func _normalize_text(text: String) -> String:
	return text.to_lower().replace("á","a").replace("é","e").replace("í","i").replace("ó","o").replace("ú","u")


## Mueve el item a una nueva posición
func move_to_position(new_position: Vector2) -> void:
	target_position = new_position
	is_moving = true


## Mueve el item a una nueva celda
func move_to_cell(new_cell: Vector2i, cell_size: int) -> void:
	current_cell = new_cell
	target_position = Vector2(new_cell.x * cell_size + cell_size / 2, 
							   new_cell.y * cell_size + cell_size / 2)
	is_moving = true


## Destruye el item
func destroy() -> void:
	queue_free()


## Intenta enviar copias de este item a cintas adyacentes (modo spawner)
func attempt_spawn() -> void:
	if not is_static_spawner:
		return
	
	var grid = GameManager.current_grid
	if not grid:
		return
	
	# Intentar en todas las direcciones: abajo, derecha, izquierda, arriba
	var directions = [Vector2.DOWN, Vector2.RIGHT, Vector2.LEFT, Vector2.UP]
	var spawned_count = 0
	
	for direction in directions:
		var output_cell = grid.get_adjacent_cell(current_cell, direction)
		
		if not grid.is_valid_cell(output_cell):
			continue
		
		var next_entity = grid.get_entity_at(output_cell)
		
		# Solo enviar a cintas transportadoras
		if next_entity and next_entity is ConveyorBelt:
			# Crear una copia de este item para enviar
			var item_scene = preload("res://entities/items/item.tscn")
			var new_item = item_scene.instantiate()
			new_item.setup(item_type, current_cell)
			new_item.is_static_spawner = false  # La copia NO es spawner
			grid.add_child(new_item)
			
			# Posicionar en este item inicialmente
			new_item.global_position = global_position
			
			# Intentar pasarlo a la cinta
			if next_entity.accept_item(new_item):
				spawned_count += 1
				print("📦 Item estático '", item_type, "' envió copia hacia ", direction)
			else:
				# Si no puede aceptarlo, destruirlo
				new_item.queue_free()
	
	if spawned_count == 0:
		#print("Item estático: no hay cintas disponibles")
		pass
