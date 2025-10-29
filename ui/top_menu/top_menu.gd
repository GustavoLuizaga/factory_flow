extends CanvasLayer

## Menú superior con botones de imagen para arrastrar entidades al grid

@onready var conveyor_up_btn: DraggableButton = $Panel/HBoxContainer/ConveyorUpContainer/ConveyorUpBtn
@onready var conveyor_down_btn: DraggableButton = $Panel/HBoxContainer/ConveyorDownContainer/ConveyorDownBtn
@onready var conveyor_left_btn: DraggableButton = $Panel/HBoxContainer/ConveyorLeftContainer/ConveyorLeftBtn
@onready var conveyor_right_btn: DraggableButton = $Panel/HBoxContainer/ConveyorRightContainer/ConveyorRightBtn
@onready var machine_btn: DraggableButton = $Panel/HBoxContainer/MachineContainer/MachineBtn


func _ready() -> void:
	# Los botones ya tienen sus escenas e imágenes asignadas en la escena .tscn
	print("TopMenu inicializado con imágenes y etiquetas de orientación")
