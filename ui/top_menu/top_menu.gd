extends CanvasLayer

## Menú superior con botones de imagen para arrastrar entidades al grid

@onready var conveyor_up_btn: DraggableButton = $Panel/HBoxContainer/ConveyorUpContainer/ConveyorUpBtn
@onready var conveyor_down_btn: DraggableButton = $Panel/HBoxContainer/ConveyorDownContainer/ConveyorDownBtn
@onready var conveyor_left_btn: DraggableButton = $Panel/HBoxContainer/ConveyorLeftContainer/ConveyorLeftBtn
@onready var conveyor_right_btn: DraggableButton = $Panel/HBoxContainer/ConveyorRightContainer/ConveyorRightBtn
@onready var machine_btn: DraggableButton = $Panel/HBoxContainer/MachineContainer/MachineBtn

# Referencias a las etiquetas (ahora son hijos de los botones)
@onready var label_up: Label = $Panel/HBoxContainer/ConveyorUpContainer/ConveyorUpBtn/Label
@onready var label_down: Label = $Panel/HBoxContainer/ConveyorDownContainer/ConveyorDownBtn/Label
@onready var label_left: Label = $Panel/HBoxContainer/ConveyorLeftContainer/ConveyorLeftBtn/Label
@onready var label_right: Label = $Panel/HBoxContainer/ConveyorRightContainer/ConveyorRightBtn/Label


func _ready() -> void:
	# Estilizar solo las etiquetas de las cintas
	style_label(label_up)
	style_label(label_down)
	style_label(label_left)
	style_label(label_right)
	
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
