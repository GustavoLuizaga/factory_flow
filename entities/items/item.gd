extends Node2D
class_name Item

## Item que representa un material o producto en el juego
## Puede moverse por cintas transportadoras y ser procesado por máquinas

@export var item_type: String = "Papel"
@export var move_speed: float = 100.0

var current_cell: Vector2i = Vector2i.ZERO
var is_moving: bool = false
var target_position: Vector2 = Vector2.ZERO

@onready var visual: ColorRect = $Visual
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
	if visual:
		visual.color = GameManager.get_material_color(item_type)
	if label:
		label.text = item_type.substr(0, 3).to_upper()


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
