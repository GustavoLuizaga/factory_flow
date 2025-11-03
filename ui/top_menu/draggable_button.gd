extends TextureButton
class_name DraggableButton

## Botón con imagen que se puede arrastrar para colocar entidades en el grid

signal drag_started(button: DraggableButton)
signal drag_ended()

@export var entity_scene: PackedScene
@export var entity_name: String = "Entity"
@export var conveyor_direction: ConveyorBelt.Direction = ConveyorBelt.Direction.RIGHT

var is_dragging: bool = false
var drag_preview: Node2D = null
var is_touch_inside: bool = false


func _ready() -> void:
	# Configurar el botón para que sea touch-friendly
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS  # Activar en press, no en release
	
	# Conectar gui_input para capturar eventos táctiles directamente
	gui_input.connect(_on_gui_input)
	
	# Permitir que los eventos pasen a través después de procesarlos
	mouse_filter = Control.MOUSE_FILTER_STOP


func _on_gui_input(event: InputEvent) -> void:
	# Detectar cuando se presiona sobre el botón (mouse o touch)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("🖱️ Mouse detectado en botón: ", entity_name)
			is_touch_inside = true
			start_drag()
			accept_event()  # Marcar el evento como manejado
	elif event is InputEventScreenTouch:
		if event.pressed:
			print("👆 Touch detectado en botón: ", entity_name, " - Index: ", event.index)
			is_touch_inside = true
			start_drag()
			accept_event()  # Marcar el evento como manejado
	else:
		print("❓ Evento desconocido en botón: ", event.get_class())


func _process(_delta: float) -> void:
	if is_dragging and drag_preview:
		# Obtener posición del mouse/touch directamente
		var mouse_pos = get_viewport().get_mouse_position()
		
		# Convertir a posición global del canvas usando la cámara
		var camera = get_viewport().get_camera_2d()
		if camera:
			# Calcular offset desde el centro de la pantalla
			var viewport_size = get_viewport().get_visible_rect().size
			var offset = (mouse_pos - viewport_size / 2) / camera.zoom
			drag_preview.global_position = camera.get_screen_center_position() + offset
		else:
			drag_preview.global_position = mouse_pos


# Capturar eventos globales de input para detectar cuando se suelta
func _input(event: InputEvent) -> void:
	if not is_dragging:
		return
	
	# Detectar fin de arrastre con mouse
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			print("🖱️ Mouse soltado - finalizando drag")
			end_drag()
			get_viewport().set_input_as_handled()
	
	# Detectar fin de arrastre con touch (CRÍTICO PARA MÓVILES)
	elif event is InputEventScreenTouch:
		if not event.pressed:
			print("👆 Touch soltado - finalizando drag")
			end_drag()
			get_viewport().set_input_as_handled()


## Inicia el arrastre
func start_drag() -> void:
	if not entity_scene:
		print("❌ Error: No hay escena asignada a este botón")
		return
	
	if is_dragging:
		return
	
	is_dragging = true
	create_drag_preview()
	drag_started.emit(self)
	
	# Feedback visual: hacer el botón más oscuro mientras se arrastra
	modulate = Color(0.7, 0.7, 0.7, 1.0)
	
	print("🟢 Drag iniciado: ", entity_name)


## Crea un preview visual del objeto siendo arrastrado
func create_drag_preview() -> void:
	if drag_preview:
		drag_preview.queue_free()
	
	# Instanciar la entidad como preview
	drag_preview = entity_scene.instantiate()
	
	# Agregar al nivel principal, no al CanvasLayer (buscar cualquier nivel activo)
	var level = get_tree().current_scene
	if level:
		level.add_child(drag_preview)
	else:
		print("❌ Error: No se encontró el nivel actual")
		drag_preview.queue_free()
		drag_preview = null
		return
	
	# Configurar dirección si es una cinta
	if drag_preview is ConveyorBelt:
		drag_preview.direction = conveyor_direction
		drag_preview.update_direction()
		drag_preview.update_visual()
	
	# Hacerlo semi-transparente
	drag_preview.modulate = Color(1, 1, 1, 0.6)


## Termina el arrastre y coloca la entidad si es válido
func end_drag() -> void:
	if not is_dragging:
		return
	
	is_dragging = false
	is_touch_inside = false
	drag_ended.emit()
	
	# Restaurar color del botón
	modulate = Color(1, 1, 1, 1)
	
	if not drag_preview:
		return
	
	var grid = GameManager.current_grid
	if not grid:
		print("⚠️ No hay grid disponible")
		drag_preview.queue_free()
		drag_preview = null
		return
	
	# Usar la posición global del preview para calcular la celda
	var world_pos = drag_preview.global_position
	var cell = grid.world_to_grid(world_pos)
	
	print("🎯 Soltando en celda: ", cell, " (posición: ", world_pos, ")")
	
	# Verificar si se puede colocar
	if grid.is_valid_cell(cell) and not grid.is_cell_occupied(cell):
		# Remover del nivel y agregar al grid
		drag_preview.get_parent().remove_child(drag_preview)
		grid.add_child(drag_preview)
		
		# Restaurar opacidad
		drag_preview.modulate = Color(1, 1, 1, 1)
		
		# Colocar en el grid
		if grid.place_entity(drag_preview, cell):
			print("✅ Entidad colocada exitosamente en celda ", cell)
		else:
			print("❌ Error al colocar entidad")
			drag_preview.queue_free()
	else:
		print("❌ Celda inválida u ocupada: ", cell)
		drag_preview.queue_free()
	
	drag_preview = null
