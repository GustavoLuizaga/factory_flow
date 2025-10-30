extends Node2D
class_name Item

## Item que representa un material o producto en el juego
## Puede moverse por cintas transportadoras y ser procesado por máquinas

@export var item_type: String = "Papel"
@export var move_speed: float = 100.0

var current_cell: Vector2i = Vector2i.ZERO
var is_moving: bool = false
var target_position: Vector2 = Vector2.ZERO

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
	"Ventana con marco de madera": "res://assets/images/Ventana_con_marco_de_madera.png"
}

@onready var sprite: Sprite2D = $Sprite
@onready var label: Label = $Label


func _ready() -> void:
	update_visual()


func _process(delta: float) -> void:
	if is_moving:
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
	if sprite and sprite_paths.has(item_type):
		# Cargar la textura
		var texture = load(sprite_paths[item_type]) as Texture2D
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
		color_rect.color = GameManager.get_material_color(item_type)
		add_child(color_rect)
		sprite.visible = false
	
	if label:
		label.text = item_type.substr(0, 3).to_upper()
		label.visible = false  # Ocultar etiqueta si hay sprite


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
