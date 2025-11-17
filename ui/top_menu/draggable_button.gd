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
var price_label: Label = null  # NUEVO: Label para mostrar el precio


func _ready() -> void:
	# Configurar el botón para que sea touch-friendly
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS  # Activar en press, no en release
	
	# Conectar gui_input para capturar eventos táctiles directamente
	gui_input.connect(_on_gui_input)
	
	# Permitir que los eventos pasen a través después de procesarlos
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# NUEVO: Esperar un frame para que el nivel inicialice la economía
	await get_tree().process_frame
	
	# NUEVO: Crear label de precio
	create_price_label()
	
	# NUEVO: Actualizar precio cuando cambie la economía
	if EconomyManager:
		EconomyManager.money_changed.connect(_on_money_changed)


## NUEVO: Crea el label que muestra el precio
func create_price_label() -> void:
	if not EconomyManager:
		return
	
	if not EconomyManager.has_economy():
		return
	
	var entity_type = get_entity_type_name()
	var cost = EconomyManager.get_cost(entity_type)
	
	if cost == 0:
		return  # Sin costo, no mostrar precio
	
	# Si ya existe un label, eliminarlo primero
	if price_label:
		price_label.queue_free()
	
	price_label = Label.new()
	price_label.name = "PriceLabel"
	price_label.text = str(cost) + "💰"
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 16)
	price_label.add_theme_color_override("font_color", Color(1, 0.85, 0, 1))
	price_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	price_label.add_theme_constant_override("outline_size", 2)
	price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Usar anchors para posicionar
	price_label.anchor_left = 0
	price_label.anchor_top = 1
	price_label.anchor_right = 1
	price_label.anchor_bottom = 1
	price_label.offset_top = -20
	price_label.offset_bottom = 0
	price_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	price_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	
	add_child(price_label)


## NUEVO: Actualiza el color del precio según el balance
func _on_money_changed(new_amount: int) -> void:
	if not price_label:
		return
	
	var entity_type = get_entity_type_name()
	if EconomyManager.can_afford(entity_type):
		price_label.add_theme_color_override("font_color", Color(1, 0.85, 0, 1))  # Dorado
	else:
		price_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))  # Rojo


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
	
	# NUEVO: Verificar si hay suficiente dinero
	var entity_type = get_entity_type_name()
	if EconomyManager and not EconomyManager.can_afford(entity_type):
		print("❌ No hay suficiente dinero para: ", entity_type)
		# Feedback visual
		modulate = Color(1, 0.3, 0.3, 1.0)
		await get_tree().create_timer(0.2).timeout
		modulate = Color(1, 1, 1, 1.0)
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
		# NUEVO: Intentar comprar la entidad
		var entity_type = get_entity_type_name()
		if EconomyManager and not EconomyManager.try_purchase(entity_type):
			print("❌ Compra cancelada: fondos insuficientes")
			drag_preview.queue_free()
			drag_preview = null
			return
		
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


## Obtiene el tipo de entidad para el sistema de economía
func get_entity_type_name() -> String:
	if entity_name.contains("Cinta"):
		return "conveyor"
	elif entity_name.contains("Ultimate-Máquina"):
		return "ultimate_fusion_machine"
	elif entity_name.contains("Super-Máquina"):
		return "super_fusion_machine"
	elif entity_name.contains("Máquina"):
		return "fusion_machine"
	return ""
