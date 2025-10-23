extends Node2D
class_name HubObjective

@export var num_slots: int = 4
@export var slot_size: int = 64
@export var spacing: int = 8

@onready var background: ColorRect = $Background
@onready var container: GridContainer = $Container

var objectives: Array = []

func _ready() -> void:
	setup_background()
	setup_container()
	populate_slots()

func setup_background() -> void:
	background.color = Color(0.1, 0.1, 0.15, 0.9)
	background.size = Vector2(
		(num_slots * (slot_size + spacing)) + spacing,
		slot_size + spacing * 2
	)

func setup_container() -> void:
	container.columns = num_slots
	container.position = Vector2(spacing, spacing)
	container.custom_minimum_size = Vector2(num_slots * slot_size, slot_size)
	container.add_theme_constant_override("hseparation", spacing)
	container.add_theme_constant_override("vseparation", spacing)

func populate_slots() -> void:
	for child in container.get_children():
		child.queue_free()
	for i in range(num_slots):
		var slot = ColorRect.new()
		slot.color = Color(0.25, 0.25, 0.3, 1)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
		slot.custom_minimum_size = Vector2(slot_size, slot_size)
		container.add_child(slot)

# Añade un nuevo objetivo al contenedor visual
func add_objective(objective_text: String) -> void:
	var slot = ColorRect.new()
	slot.color = Color(0.2, 0.6, 0.2, 1)  # Verde oscuro
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slot.custom_minimum_size = Vector2(200, 40)

	# Crear texto
	var label = Label.new()
	label.text = objective_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_font_size_override("font_size", 16)
	
	slot.add_child(label)
	container.add_child(slot)
