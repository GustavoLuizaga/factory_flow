extends CanvasLayer

## Menú superior NIVEL 2 - Incluye botón de Super-Máquina

signal delete_mode_changed(is_active: bool)

@onready var conveyor_up_btn: DraggableButton = $Panel/HBoxContainer/ConveyorUpContainer/ConveyorUpBtn
@onready var conveyor_down_btn: DraggableButton = $Panel/HBoxContainer/ConveyorDownContainer/ConveyorDownBtn
@onready var conveyor_left_btn: DraggableButton = $Panel/HBoxContainer/ConveyorLeftContainer/ConveyorLeftBtn
@onready var conveyor_right_btn: DraggableButton = $Panel/HBoxContainer/ConveyorRightContainer/ConveyorRightBtn
@onready var machine_btn: DraggableButton = $Panel/HBoxContainer/MachineContainer/MachineBtn
@onready var super_machine_btn: DraggableButton = $Panel/HBoxContainer/SuperMachineContainer/SuperMachineBtn

# Referencias a las etiquetas
@onready var label_up: Label = $Panel/HBoxContainer/ConveyorUpContainer/ConveyorUpBtn/Label
@onready var label_down: Label = $Panel/HBoxContainer/ConveyorDownContainer/ConveyorDownBtn/Label
@onready var label_left: Label = $Panel/HBoxContainer/ConveyorLeftContainer/ConveyorLeftBtn/Label
@onready var label_right: Label = $Panel/HBoxContainer/ConveyorRightContainer/ConveyorRightBtn/Label

var delete_mode: bool = false
var delete_btn: TextureButton = null


func _ready() -> void:
	# Estilizar etiquetas
	style_label(label_up)
	style_label(label_down)
	style_label(label_left)
	style_label(label_right)
	
	# Crear botón de borrar
	if not delete_btn:
		create_delete_button()
	
	# Conectar botón de borrar
	if delete_btn:
		delete_btn.pressed.connect(_on_delete_btn_pressed)
	
	# Conectar señales de draggable
	conveyor_up_btn.drag_started.connect(_on_any_drag_started)
	conveyor_down_btn.drag_started.connect(_on_any_drag_started)
	conveyor_left_btn.drag_started.connect(_on_any_drag_started)
	conveyor_right_btn.drag_started.connect(_on_any_drag_started)
	machine_btn.drag_started.connect(_on_any_drag_started)
	super_machine_btn.drag_started.connect(_on_any_drag_started)  # NUEVO
	
	print("TopMenu Nivel 2 inicializado con Super-Máquina")


## Aplica estilo a una etiqueta
func style_label(label: Label) -> void:
	if not label:
		return
	
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_delete_btn_pressed() -> void:
	delete_mode = !delete_mode
	
	if delete_btn:
		if delete_mode:
			delete_btn.modulate = Color(1.5, 0.5, 0.5, 1.0)
			print("🗑️ Modo BORRAR activado")
		else:
			delete_btn.modulate = Color(1, 1, 1, 1)
			print("✋ Modo BORRAR desactivado")
	
	delete_mode_changed.emit(delete_mode)


func _on_any_drag_started(button: DraggableButton) -> void:
	if delete_mode:
		delete_mode = false
		if delete_btn:
			delete_btn.modulate = Color(1, 1, 1, 1)
		delete_mode_changed.emit(false)
		print("✋ Modo BORRAR desactivado automáticamente")


func is_delete_mode_active() -> bool:
	return delete_mode


func create_delete_button() -> void:
	print("📦 Creando botón de borrar...")
	
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
	delete_btn.custom_minimum_size = Vector2(64, 64)
	delete_container.add_child(delete_btn)
	
	var color_rect = ColorRect.new()
	color_rect.color = Color(0.8, 0.2, 0.2, 1)
	color_rect.custom_minimum_size = Vector2(64, 64)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	delete_btn.add_child(color_rect)
	
	var label = Label.new()
	label.text = "🗑️"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 32)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.add_child(label)
	
	print("✅ Botón de borrar creado")
