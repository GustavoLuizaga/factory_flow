extends CanvasLayer

## Menú superior con botones de imagen para arrastrar entidades al grid

signal delete_mode_changed(is_active: bool)

@onready var conveyor_up_btn: DraggableButton = $Panel/HBoxContainer/ConveyorUpContainer/ConveyorUpBtn
@onready var conveyor_down_btn: DraggableButton = $Panel/HBoxContainer/ConveyorDownContainer/ConveyorDownBtn
@onready var conveyor_left_btn: DraggableButton = $Panel/HBoxContainer/ConveyorLeftContainer/ConveyorLeftBtn
@onready var conveyor_right_btn: DraggableButton = $Panel/HBoxContainer/ConveyorRightContainer/ConveyorRightBtn
@onready var machine_btn: DraggableButton = $Panel/HBoxContainer/MachineContainer/MachineBtn
@onready var delete_icon_normal = preload("res://assets/images/eliminar.png")

# Referencias a las etiquetas (ahora son hijos de los botones)
@onready var label_up: Label = $Panel/HBoxContainer/ConveyorUpContainer/ConveyorUpBtn/Label
@onready var label_down: Label = $Panel/HBoxContainer/ConveyorDownContainer/ConveyorDownBtn/Label
@onready var label_left: Label = $Panel/HBoxContainer/ConveyorLeftContainer/ConveyorLeftBtn/Label
@onready var label_right: Label = $Panel/HBoxContainer/ConveyorRightContainer/ConveyorRightBtn/Label

var pause_btn: TextureButton = null
var delete_mode: bool = false
var delete_btn: TextureButton = null  # Se crea dinámicamente


func _ready() -> void:
	# Obtener el botón de pausa
	pause_btn = $Panel/HBoxContainer/PauseButtonContainer/PauseBtn
	
	# Estilizar solo las etiquetas de las cintas
	style_label(label_up)
	style_label(label_down)
	style_label(label_left)
	style_label(label_right)
	
	# Crear botón de borrar si no existe en la escena
	if not delete_btn:
		create_delete_button()
	
	# Conectar el botón de borrar
	if delete_btn:
		delete_btn.pressed.connect(_on_delete_btn_pressed)
	
	# Conectar el botón de pausa
	if pause_btn:
		pause_btn.pressed.connect(_on_pause_btn_pressed)
		print("✅ Botón de pausa conectado correctamente")
	else:
		print("❌ No se encontró el botón de pausa")
	
	# Conectar señales de los botones draggable para desactivar modo borrar
	conveyor_up_btn.drag_started.connect(_on_any_drag_started)
	conveyor_down_btn.drag_started.connect(_on_any_drag_started)
	conveyor_left_btn.drag_started.connect(_on_any_drag_started)
	conveyor_right_btn.drag_started.connect(_on_any_drag_started)
	machine_btn.drag_started.connect(_on_any_drag_started)
	
	print("TopMenu inicializado con flechas superpuestas en cintas")


## Aplica estilo a una etiqueta
func style_label(label: Label) -> void:
	if not label:
		return
	
	# Hacer el texto más grande y visible
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	
	# Asegurar que no interfiera con los clics
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE


## Callback cuando se presiona el botón de borrar
func _on_delete_btn_pressed() -> void:
	delete_mode = !delete_mode  # Toggle
	
	# Cambiar el color del botón para indicar el modo activo
	if delete_btn:
		if delete_mode:
			delete_btn.modulate = Color(1.5, 0.5, 0.5, 1.0)  # Rojo brillante
			print("🗑️ Modo BORRAR activado")
		else:
			delete_btn.modulate = Color(1, 1, 1, 1)  # Normal
			print("✋ Modo BORRAR desactivado")
	
	# Emitir señal para que el nivel sepa del cambio
	delete_mode_changed.emit(delete_mode)


## Callback cuando se inicia el arrastre de cualquier botón
func _on_any_drag_started(button: DraggableButton) -> void:
	# Desactivar modo borrar automáticamente
	if delete_mode:
		delete_mode = false
		if delete_btn:
			delete_btn.modulate = Color(1, 1, 1, 1)
		delete_mode_changed.emit(false)
		print("✋ Modo BORRAR desactivado automáticamente (iniciando arrastre)")


## Obtener el estado del modo borrar
func is_delete_mode_active() -> bool:
	return delete_mode


## Crea el botón de borrar programáticamente
func create_delete_button() -> void:
	print("📦 Creando botón de borrar programáticamente...")
	
	var hbox = $Panel/HBoxContainer
	if not hbox:
		print("❌ No se encontró HBoxContainer")
		return
	

	var delete_container = MarginContainer.new()
	delete_container.name = "DeleteContainer"
	delete_container.add_theme_constant_override("margin_left", 10)
	delete_container.add_theme_constant_override("margin_right", 10)
	delete_container.add_theme_constant_override("margin_top", 10)
	delete_container.add_theme_constant_override("margin_bottom", 10)
	hbox.add_child(delete_container)
	
	delete_btn = TextureButton.new()
	delete_btn.name = "DeleteBtn"
	
	delete_btn.texture_normal = delete_icon_normal
	delete_btn.ignore_texture_size = true 
	delete_btn.custom_minimum_size = Vector2(50, 50)
	
	delete_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

	delete_container.add_child(delete_btn)
	
	# Mover el botón de pausa al final (después del botón de eliminar)
	if pause_btn and pause_btn.get_parent():
		var pause_button_container = pause_btn.get_parent()
		hbox.move_child(pause_button_container, hbox.get_child_count() - 1)
	
	# Crear fondo rojo (BORRADO)
	#var color_rect = ColorRect.new()
	#color_rect.color = Color(0.8, 0.2, 0.2, 1)
	#color_rect.custom_minimum_size = Vector2(64, 64)
	#color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	#delete_btn.add_child(color_rect)
	
	# Crear etiqueta con emoji (BORRADO)
	#var label = Label.new()
	#label.text = "🗑️"
	#label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# ... (más propiedades del label) ...
	#color_rect.add_child(label)
	
	print("✅ Botón de borrar con imagen PNG creado exitosamente")


## Callback cuando se presiona el botón de pausa
func _on_pause_btn_pressed() -> void:
	# Buscar el menú de pausa en el nivel actual
	var current_scene = get_tree().current_scene
	var pause_menu = current_scene.find_child("PauseMenu", true, false)
	
	if pause_menu:
		pause_menu.toggle_pause()
		print("⏸️ Botón de pausa presionado")
	else:
		print("❌ No se encontró PauseMenu en la escena actual")
