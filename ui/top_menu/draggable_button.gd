extends Button
class_name DraggableButton

## Botón que se puede arrastrar para colocar entidades en el grid

signal drag_started(button: DraggableButton)
signal drag_ended()

@export var entity_scene: PackedScene
@export var entity_name: String = "Entity"
@export var conveyor_direction: ConveyorBelt.Direction = ConveyorBelt.Direction.RIGHT

var is_dragging: bool = false
var drag_preview: Node2D = null


func _ready() -> void:
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	start_drag()


func _process(_delta: float) -> void:
	if is_dragging and drag_preview:
		drag_preview.global_position = get_global_mouse_position()


func _input(event: InputEvent) -> void:
	if is_dragging:
		if event is InputEventMouseButton:
			if not event.pressed:
				end_drag()
		elif event is InputEventScreenTouch:
			if not event.pressed:
				end_drag()


## Inicia el arrastre
func start_drag() -> void:
	if not entity_scene:
		print("Error: No hay escena asignada a este botón")
		return
	
	is_dragging = true
	create_drag_preview()
	drag_started.emit(self)
	print("Drag iniciado: ", entity_name)


## Crea un preview visual del objeto siendo arrastrado
func create_drag_preview() -> void:
	if drag_preview:
		drag_preview.queue_free()
	
	# Instanciar la entidad como preview
	drag_preview = entity_scene.instantiate()
	get_tree().root.add_child(drag_preview)
	
	# Configurar dirección si es una cinta
	if drag_preview is ConveyorBelt:
		drag_preview.direction = conveyor_direction
		drag_preview.update_direction()
		drag_preview.update_visual()
	
	# Hacerlo semi-transparente
	drag_preview.modulate = Color(1, 1, 1, 0.6)
	drag_preview.global_position = get_global_mouse_position()


## Termina el arrastre y coloca la entidad si es válido
func end_drag() -> void:
	if not is_dragging:
		return
	
	is_dragging = false
	drag_ended.emit()
	
	if not drag_preview:
		return
	
	var grid = GameManager.current_grid
	if not grid:
		print("No hay grid disponible")
		drag_preview.queue_free()
		drag_preview = null
		return
	
	# Obtener la celda donde se soltó
	var mouse_pos = get_global_mouse_position()
	var cell = grid.world_to_grid(mouse_pos)
	
	print("Intentando colocar en celda: ", cell)
	
	# Verificar si se puede colocar
	if grid.is_valid_cell(cell) and not grid.is_cell_occupied(cell):
		# Remover el preview del root
		drag_preview.get_parent().remove_child(drag_preview)
		
		# Agregar al grid
		grid.add_child(drag_preview)
		
		# Restaurar opacidad
		drag_preview.modulate = Color(1, 1, 1, 1)
		
		# Colocar en el grid
		if grid.place_entity(drag_preview, cell):
			print("¡Entidad colocada exitosamente!")
		else:
			print("Error al colocar entidad")
			drag_preview.queue_free()
	else:
		print("Celda inválida u ocupada")
		drag_preview.queue_free()
	
	drag_preview = null
