extends Node2D
class_name MaterialSpawner

## Spawner que genera materiales automáticamente
## Los materiales aparecen aleatoriamente cada cierto intervalo

@export var material_type: String = "Papel"
@export var spawn_interval: float = 3.0
@export var auto_spawn: bool = true

var current_cell: Vector2i = Vector2i.ZERO
var spawn_timer: float = 0.0
var current_item: Item = null

@onready var visual: ColorRect = $Visual
@onready var label: Label = $Label


func _ready() -> void:
	update_visual()
	spawn_timer = spawn_interval  # Spawn inmediato al inicio


func _process(delta: float) -> void:
	if auto_spawn:
		spawn_timer += delta
		
		if spawn_timer >= spawn_interval:
			attempt_spawn()
			spawn_timer = 0.0


## Callback cuando se coloca en el grid
func on_placed_in_grid(cell: Vector2i) -> void:
	current_cell = cell
	print("Spawner de ", material_type, " colocado en: ", cell)


## Actualiza el visual según el tipo de material
func update_visual() -> void:
	if visual:
		visual.color = GameManager.get_material_color(material_type)
	
	if label:
		label.text = material_type.substr(0, 3).to_upper()


## Intenta spawnear un item
func attempt_spawn() -> void:
	# Si ya hay un item aquí, no spawner
	if current_item != null:
		return
	
	var grid = GameManager.current_grid
	if not grid:
		return
	
	# Intentar spawnear en la celda de abajo
	var output_cell = grid.get_adjacent_cell(current_cell, Vector2.DOWN)
	
	if not grid.is_valid_cell(output_cell):
		print("Spawner: celda de salida inválida")
		return
	
	var next_entity = grid.get_entity_at(output_cell)
	
	if next_entity and next_entity.has_method("accept_item"):
		# Crear el item
		var item_scene = preload("res://entities/items/item.tscn")
		var new_item = item_scene.instantiate()
		new_item.setup(material_type, current_cell)
		grid.add_child(new_item)
		
		# Posicionar en el spawner inicialmente
		new_item.global_position = global_position
		
		# Intentar pasarlo a la cinta/entidad de abajo
		if next_entity.accept_item(new_item):
			print("Spawner generó: ", material_type)
		else:
			# Si no puede aceptarlo, destruirlo
			new_item.queue_free()
	else:
		print("Spawner: no hay receptor válido en la salida")
