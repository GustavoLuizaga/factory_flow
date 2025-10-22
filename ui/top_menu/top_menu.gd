extends CanvasLayer

## Menú superior con botones para arrastrar entidades al grid

@onready var conveyor_up_btn: DraggableButton = $Panel/HBoxContainer/ConveyorUpBtn
@onready var conveyor_down_btn: DraggableButton = $Panel/HBoxContainer/ConveyorDownBtn
@onready var conveyor_left_btn: DraggableButton = $Panel/HBoxContainer/ConveyorLeftBtn
@onready var conveyor_right_btn: DraggableButton = $Panel/HBoxContainer/ConveyorRightBtn
@onready var machine_btn: DraggableButton = $Panel/HBoxContainer/MachineBtn


func _ready() -> void:
	# Los botones ya tienen sus escenas asignadas en la escena .tscn
	print("TopMenu inicializado")
